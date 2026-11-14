#!/usr/bin/env bash
# Builds every cut of the film from source.
#   bash film/build.sh            # main film, social cut, loop, poster
#   bash film/build.sh main       # one cut
# Needs: node (with sharp), python3 (with numpy), ffmpeg. Output: film/*.mp4, film/poster.jpg
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p out
CUTS="${1:-main social loop}"
node render.cjs poster
for cut in $CUTS; do
  node -e "
    const F=require('./film.cjs'),fs=require('fs'),path=require('path');
    const cut={main:F.MAIN,social:F.SOCIAL,loop:F.LOOP}['$cut'];
    const man=JSON.parse(fs.readFileSync('../audio/manifest.json','utf8')).sentences;
    const voice=cut.voice.map(([t,line,trim])=>{ if(!man[line]) throw new Error('no recording for: '+line); return [t,path.resolve('../audio',man[line]),trim||null]; });
    fs.writeFileSync('out/spec-$cut.json',JSON.stringify({name:cut.name,dur:cut.dur,cues:cut.cues,voice}));
    console.log(cut.name);" > out/name-$cut.txt
  name=$(cat out/name-$cut.txt)
  total=$(node -e "const F=require('./film.cjs');const c={main:F.MAIN,social:F.SOCIAL,loop:F.LOOP}['$cut'];console.log(Math.round(c.dur*F.FPS))")
  half=$((total/2))
  # two halves at once: one per core
  node render.cjs $cut 0 $half & node render.cjs $cut $half $total & wait
  printf "file '%s'\nfile '%s'\n" "$name.0-$half.mp4" "$name.$half-$total.mp4" > out/concat-$cut.txt
  ffmpeg -y -loglevel error -f concat -safe 0 -i out/concat-$cut.txt -c copy out/$name.video.mp4
  if [ "$cut" = "loop" ]; then
    ffmpeg -y -loglevel error -i out/$name.video.mp4 -an -vf scale=1280:720 -c:v libx264 -preset slow -crf 24 -pix_fmt yuv420p -movflags +faststart $name.mp4
  else
    python3 score.py out/spec-$cut.json out/$name.wav
    ffmpeg -y -loglevel error -i out/$name.video.mp4 -i out/$name.wav -c:v copy -af "loudnorm=I=-15:TP=-1.5:LRA=11" -c:a aac -b:a 192k -ar 48000 -movflags +faststart $name.mp4
  fi
  rm -f out/$name.*-*.mp4
  echo "built film/$name.mp4"
done
