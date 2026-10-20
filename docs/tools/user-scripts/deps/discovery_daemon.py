# -*- coding: utf-8 -*-
"""
多协议设备发现守护进程 —— 供 GuiPing.ahk 轮询

同时搜索两类设备:
  1. WellTrans EMS 设备: UDP 广播 255.255.255.255:8003, 收 8004 响应 (私有二进制协议)
  2. Hikvision 海康设备: UDP 多播 239.255.255.250:37020 (SADP 协议, 纯 XML)

输出 devices.txt: 每行 ip|mac|mask|gateway|type
  type: EMS 或 HIK

海康 SADP 协议要点:
  请求 (纯 XML, 无二进制头): <?xml...?><Probe><Uuid>大写UUID4</Uuid><Types>inquiry</Types></Probe>
  响应: <ProbeMatch> XML, 含 MAC/IPv4Address/IPv4SubnetMask/IPv4Gateway/DeviceDescription 等
"""
import os
import select
import socket
import sys
import time
import uuid
import xml.etree.ElementTree as ET

# --- EMS 协议常量 ---
EMS_BCAST = '255.255.255.255'
EMS_SEARCH_PORT = 8003
EMS_LISTEN_PORT = 8004
EMS_REQ = bytes.fromhex('27011520010100') + b'\xff' * 41 + bytes.fromhex('af17717c')

# --- 海康 SADP 协议常量 ---
HIK_MCAST = '239.255.255.250'
HIK_PORT = 37020

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_FILE = os.path.join(HERE, 'devices.txt')
OUT_TMP = OUT_FILE + '.tmp'

BROADCAST_INTERVAL = 2.0   # 每 2 秒发一轮搜索请求
DEVICE_TIMEOUT = 12.0      # 设备超过 12 秒无响应判离线
WRITE_INTERVAL = 1.0       # 每 1 秒写一次结果


def parse_ems(data):
    """解析 EMS 52 字节二进制响应"""
    if len(data) < 32:
        return None
    if data[0:4] != bytes.fromhex('27011520') or data[4] != 0x02:
        return None
    ip = socket.inet_ntoa(data[16:20])
    mac = ':'.join(f'{b:02x}' for b in data[9:15])  # 6 字节完整 MAC (9:12 前3 + 12:15 后3)
    mask = socket.inet_ntoa(data[20:24])
    gw = socket.inet_ntoa(data[24:28])
    return ip, mac, mask, gw, 'EMS'


def parse_hik(data):
    """解析海康 SADP <ProbeMatch> XML 响应"""
    try:
        root = ET.fromstring(data)
    except ET.ParseError:
        return None
    ip = root.findtext('IPv4Address')
    if not ip:
        return None
    mac = (root.findtext('MAC') or '').replace('-', ':')
    mask = root.findtext('IPv4SubnetMask') or ''
    gw = root.findtext('IPv4Gateway') or ''
    return ip, mac, mask, gw, 'HIK'


def build_hik_req():
    uid = str(uuid.uuid4()).upper()
    xml = (f'<?xml version="1.0" encoding="utf-8"?>'
           f'<Probe><Uuid>{uid}</Uuid><Types>inquiry</Types></Probe>')
    return xml.encode('utf-8')


def write_out(devices):
    try:
        lines = []
        for ip in sorted(devices):
            mac, mask, gw, dtype = devices[ip]
            lines.append(f'{ip}|{mac}|{mask}|{gw}|{dtype}')
        with open(OUT_TMP, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines) + ('\n' if lines else ''))
        os.replace(OUT_TMP, OUT_FILE)
    except Exception:
        pass


def main():
    # EMS socket (bind 8004 收响应)
    ems_sock = None
    try:
        ems_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        ems_sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        ems_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        ems_sock.bind(('0.0.0.0', EMS_LISTEN_PORT))
    except OSError as e:
        print(f'EMS bind {EMS_LISTEN_PORT} failed: {e}', file=sys.stderr)

    # 海康 socket (bind 37020 + 加入多播组)
    hik_sock = None
    try:
        hik_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        hik_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        hik_sock.bind(('', HIK_PORT))
        mreq = socket.inet_aton(HIK_MCAST) + socket.inet_aton('0.0.0.0')
        hik_sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
    except OSError as e:
        print(f'Hik bind {HIK_PORT} failed: {e}', file=sys.stderr)

    if not ems_sock and not hik_sock:
        write_out({})
        return

    devices = {}    # ip -> (mac, mask, gw, type)
    last_seen = {}  # ip -> timestamp
    last_bcast = 0.0
    last_hik = 0.0
    last_write = 0.0

    write_out({})

    while True:
        now = time.time()
        socks = []

        if ems_sock:
            if now - last_bcast >= BROADCAST_INTERVAL:
                try:
                    ems_sock.sendto(EMS_REQ, (EMS_BCAST, EMS_SEARCH_PORT))
                except OSError:
                    pass
                last_bcast = now
            socks.append(ems_sock)

        if hik_sock:
            if now - last_hik >= BROADCAST_INTERVAL:
                try:
                    hik_sock.sendto(build_hik_req(), (HIK_MCAST, HIK_PORT))
                except OSError:
                    pass
                last_hik = now
            socks.append(hik_sock)

        r, _, _ = select.select(socks, [], [], 1.0)
        for s in r:
            try:
                data, _addr = s.recvfrom(65536)
            except OSError:
                continue
            parsed = parse_ems(data) if s is ems_sock else parse_hik(data)
            if parsed:
                ip, mac, mask, gw, dtype = parsed
                devices[ip] = (mac, mask, gw, dtype)
                last_seen[ip] = now

        # 移除超时离线设备
        for ip in list(last_seen):
            if now - last_seen[ip] > DEVICE_TIMEOUT:
                devices.pop(ip, None)
                last_seen.pop(ip, None)

        if now - last_write >= WRITE_INTERVAL:
            write_out(devices)
            last_write = now


if __name__ == '__main__':
    main()
