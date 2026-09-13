#!/usr/bin/env bash
# Serve the reader locally (pdf.js needs http, not file://) and open it.
cd "$(dirname "$0")"
PORT="${PORT:-8765}"
( sleep 0.8; open "http://localhost:$PORT/" ) &
python3 -m http.server "$PORT"
