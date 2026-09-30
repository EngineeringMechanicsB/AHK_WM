ffmpeg -i .mp4 -vf "fps=20,scale=1600:-1:flags=lanczos,palettegen=max_colors=256" palette.png

ffmpeg -i .mp4 -i palette.png -filter_complex "fps=20,scale=1600:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=none" output.gif
