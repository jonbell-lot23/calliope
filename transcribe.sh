#!/usr/bin/env bash
# Transcribe audiobook files with whisper.cpp to get word timestamps.
# Usage: ./transcribe.sh OUTPUT.words.json audio1.mp3 [audio2.mp3 ...]
#   MODEL=/path/to/ggml-model.bin ./transcribe.sh ...   (override model)
# Output: one JSON with all words on a single global timeline, which index.html
# aligns to the PDF text in the browser.
set -euo pipefail
out="${1:?output json}"; shift
[ $# -gt 0 ] || { echo "no audio files given" >&2; exit 1; }

MODEL="${MODEL:-}"
if [ -z "$MODEL" ]; then
  for m in \
    "$HOME/Library/Application Support/superwhisper/ggml-small.en.bin" \
    "$HOME/Library/Application Support/superwhisper/ggml-medium.bin" \
    "$HOME/Library/Application Support/MacWhisper/models/ggml-model-whisper-small.bin" \
    ./models/ggml-*.bin; do
    [ -f "$m" ] && { MODEL="$m"; break; }
  done
fi
[ -f "$MODEL" ] || { echo "no whisper model found; set MODEL=/path/to/ggml-*.bin" >&2; exit 1; }
echo "model: $MODEL"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
i=0
for f in "$@"; do
  i=$((i+1)); base="$(basename "$f")"
  echo "[$i/$#] $base"
  ffmpeg -loglevel error -y -i "$f" -ar 16000 -ac 1 -c:a pcm_s16le "$tmp/$i.wav"
  # -ml 1 -sow → one segment per word, with timestamps
  whisper-cli -m "$MODEL" -f "$tmp/$i.wav" -ml 1 -sow -oj -of "$tmp/$i" -t "$(sysctl -n hw.ncpu)" -np -nt >/dev/null 2>"$tmp/$i.log" \
    || { echo "whisper failed on $base:"; tail -5 "$tmp/$i.log"; exit 1; }
  dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")"
  printf '%s\t%s\t%s\n' "$base" "$dur" "$tmp/$i.json" >> "$tmp/index.tsv"
done

python3 - "$tmp/index.tsv" "$out" <<'PY'
import json, sys
files, words, offset = [], [], 0.0
for line in open(sys.argv[1]):
    name, dur, path = line.rstrip('\n').split('\t')
    dur = float(dur)
    for seg in json.load(open(path))['transcription']:
        w = seg['text'].strip()
        if not w: continue
        words.append({'w': w, 's': round(offset + seg['offsets']['from']/1000, 2), 'e': round(offset + seg['offsets']['to']/1000, 2)})
    files.append({'name': name, 'duration': dur}); offset += dur
json.dump({'files': files, 'words': words}, open(sys.argv[2], 'w'))
print(f"wrote {sys.argv[2]}: {len(words)} words across {len(files)} file(s), {offset/60:.1f} min")
PY
