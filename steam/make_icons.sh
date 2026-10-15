#!/bin/bash
# make_icons.sh FOLDER: FOLDER/NAME.png (1024 square, as steam/badges.txt made them) -> round, soft-edged: game 64px png (colour + locked, clear corners), Steam 256 jpg (colour + locked, black corners)
R=$(cd $(dirname $0)/.. && pwd); O=${1:?usage: make_icons.sh FOLDER-OF-NAME.png}; T=$(mktemp -d); mkdir -p $T $R/neon-caster/achievements $R/steam/achievements
magick -size 256x256 xc:black -fill white -draw "circle 128,128 128,5" -blur 0x2.5 $T/mask.png
for f in $O/NC_*.png; do
  n=$(basename $f .png)
  magick $f -gravity center -crop 90%x90%+0+0 +repage -resize 256x256! $T/mask.png -alpha off -compose CopyOpacity -composite $T/$n.png
  magick $T/$n.png -colorspace Gray -level 0%,135% -fill '#1a1430' -colorize 30% $T/mask.png -alpha off -compose CopyOpacity -composite $T/${n}_locked.png
  for v in $n ${n}_locked; do
    magick $T/$v.png -background black -flatten -quality 90 $R/steam/achievements/$v.jpg
    magick $T/$v.png -resize 64x64 -strip PNG32:$R/neon-caster/achievements/$v.png
  done
done
ls $R/neon-caster/achievements | wc -l; du -sh $R/neon-caster/achievements $R/steam/achievements
rm -rf $T
