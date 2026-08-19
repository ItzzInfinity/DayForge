# Screenshot rig

Renders the real DayForge widget tree against seeded demo data and writes the
PNGs and GIFs the project README uses. Nothing here is hand-drawn, so the
gallery cannot drift from what the app actually looks like.

```bash
tool/screenshots/capture.sh                 # every scene -> docs/screenshots/
tool/screenshots/capture.sh 03-progress     # just one
tool/screenshots/make_gifs.sh               # frame sequences -> *.gif
```

| file | what it is |
| --- | --- |
| `capture_test.dart` | the scenes. One `testWidgets` per output file; the test name *is* the filename. |
| `demo_data.dart` | the invented account everything is rendered against — streaks, misses, remarks, one intraday task deliberately below its target. |
| `harness.dart` | phone-shaped surface, real fonts, and the capture helper. |
| `build_font.py` | builds the font the screenshots use (see below). |
| `capture.sh` | runs the scenes, one process each. |
| `make_gifs.sh` | assembles frame sequences into GIFs. |

## Three things that are not obvious

**One process per screenshot, and the exit code is ignored.** Rasterising a
widget tree writes a perfectly good PNG and then leaves the test runner
wedged — it never reports the test complete and sits until it times out. This
happens with a hand-rolled `RenderRepaintBoundary.toImage`, with
`matchesGoldenFile`, and on a trivial one-`Text` tree, so it is the headless
runner in this environment rather than anything about DayForge. `capture.sh`
therefore launches one process per scene and kills it as soon as the file
appears. The file is the artefact; the exit code is noise.

**The font is built, not borrowed.** Noto Sans has no `→`, `✓` or `○`, and a
headless test has no fontconfig to fall back through, so those rendered as
tofu boxes. Registering a second font under the same family does not fix it:
Flutter treats same-family faces as weight variants and the first match wins —
there is no per-glyph fallback. `build_font.py` subsets DejaVu Sans down to
just the missing codepoints (making the merge conflict-free) and merges them
into Noto, so the coverage lives inside one file.

**`debugDisableShadows` defaults to true in tests.** Left alone, every
elevation shadow paints as a hard black shape — which is where the heavy black
ring around the + button came from. The harness turns it off.

## Adding a scene

Add a `testWidgets` whose name is the filename you want, call `capture` at the
end of it, and add that name to `STILLS` in `capture.sh`. Films are the same
but one test per frame — capturing twice in one test does not work, for the
reason above — named `film-<name>-NN`, landing in `docs/screenshots/film/`.
