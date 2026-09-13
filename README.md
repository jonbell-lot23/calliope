# Calliope

Calliope, muse of epic poetry, "beautiful voice". A reader for when you own the PDF **and** the audiobook. One screen:
the book in the middle, the narrator in a sidebar, and the two stay in step.
Nothing leaves your machine.

- Press play and the narrated sentence is washed in the PDF, the current word marked,
  and the page follows along.
- Click any word and the narrator jumps there.
- Scroll off on your own while it plays and the sidebar notices: **Play from here**
  or **Back to narrator**. Same when paused: read ahead, then play from where you are.
- Search the book (`/`) to find where you are.
- On a phone the sidebar becomes a bottom sheet; swipe up for the full player.

## Run it

```sh
./serve.sh            # serves on http://localhost:8765 and opens it
```

Books can be served from a `books/` folder listed in `books.json` (see `books.example.json`);
both are git-ignored, so your books stay on your machine. Locally, *Reality Is Broken* is there: `books/reality-is-broken/` holds the PDF, the 165 CD tracks
stitched into one `reality-is-broken-book.mp3` (ffmpeg concat, no re-encode), and its transcript.
Click the cover, or go straight to `http://localhost:8765/?book=reality`.

To add another book, drop its files in a `books/<name>/` folder and add an entry
to `books.json` (fields: title, author, cover, pdf, audio (list), words).

You can also drag a PDF plus its audio files onto the page, use the 📂 button, or
open a served folder directly by URL:

```
http://localhost:8765/?pdf=sample/sample.pdf&audio=sample/sample.mp3&words=sample/sample.words.json
```

The last book you opened is remembered (files are cached in the browser's
IndexedDB), along with your position, mode, speed, and any sync marks.

## Getting accurate sync

Out of the box, without a transcript, the app maps your place *proportionally*
(word 40% through the book ≈ 40% through the audio). That is rough. Two ways to
make it exact:

1. **Transcribe once with whisper.cpp** (recommended; fully local):

   ```sh
   ./transcribe.sh mybook.words.json audio/*.mp3
   ```

   It converts the audio with ffmpeg, runs `whisper-cli` with word-level
   timestamps, and writes one JSON with every spoken word on a global timeline.
   Pick that file as the "Transcript" when opening the book. The app then
   aligns transcript words to the PDF's words in the browser (unique 4-gram
   matches, longest-increasing-subsequence to keep it monotonic, then densified),
   which gives sentence-accurate switching. Expect roughly real-time speed with
   the small.en model on Apple Silicon, so a 10-hour book is a long lunch.
   Set `MODEL=/path/to/ggml-*.bin` to pick a different model.

2. **Mark it by hand.** Press 📍 (or "wrong spot? fix it" in Listen mode). The
   audio keeps playing and the PDF appears; click the word the narrator is on.
   Each mark is a sync anchor and the mapping is interpolated between them. A
   handful of marks per chapter is usually enough. Marks are saved per book.

## Controls

| Key | Action |
|---|---|
| `Space` | play / pause |
| `←` / `→` | skip 15 s |
| `Enter` | back to the narrator |
| `/` | search the book; `Enter` / `↑` `↓` walk the hits, `Esc` clears |
| click a word | narrator jumps there |
| 📍 | fix the sync: click the word the narrator is on |

## Hosted

Live at **https://calliope-reader.vercel.app** (source: https://github.com/jonbell-lot23/calliope).
The app is a static site (one file). Hosted copies carry only the sample book:
drag your PDF and audio onto the page and they are cached in your browser only.

## Files

- `index.html` — the whole app (pdf.js from cdnjs, no build step)
- `transcribe.sh` — whisper.cpp → `*.words.json`
- `serve.sh` — tiny static server (pdf.js needs http, not file://)
- `books.json`, `books/` — the shelf and the books on it
- `sample/` — a short generated sample book

## Prior art

Amazon's Whispersync / Audible "Read & Listen" do this for books bought from
Amazon. Storyteller (open source, EPUB-only) and Spokt (iOS, closed) do it for
your own files. None of them is a lightweight local app that takes a PDF and
MP3s, hence this.
