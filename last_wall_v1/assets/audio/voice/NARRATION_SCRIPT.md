# Last Wall — Narration Script

One narrator, calm and warm, like an old storyteller. About **1 minute 40 seconds** in total.

**How to record**
- Record each line as its own file and save it in this folder (`assets/audio/voice/`) with the exact file name shown (`.ogg` is best, `.wav` also works).
- Leave about half a second of silence at the start and end of each file.
- The game plays each line over its picture and moves to the next picture when the line ends. Players can also click to go faster or press **Skip story**.
- Until a file exists, the game simply shows the text for a few seconds instead.
- The text on screen comes from `scripts/data/story_data.gd`. If you change a line while recording, change it there too so the subtitles match.

---

## Opening story

### `narration_01` — picture: map of the island with five walls
> Long ago, the first king of our island, King Aldren, built a wall of white stone around his small town. When the town grew, his son built a second wall beyond it. And so it went. Five kings. Five walls. Each one further out, until the fifth stood on the very edge of the sea.

### `narration_02` — picture: the five kings
> Aldren. Berin. Corwin. Doran. Edmund. For two hundred years their walls kept us safe. But the people loved the first wall most. The oldest. The strongest. They called it *the Last Wall*… because if every other wall should fall, it would be the last thing standing between the sea and our homes.

### `narration_03` — picture: a field of swords and helmets
> Then the raiders came from across the sea. We fought them on every wall… and we won. But victory has a price. Most of our soldiers never came home.

### `narration_04` — picture: red sails on the sea
> We had only just buried our brave ones when the watchmen saw sails on the horizon. More ships than before. Many more. And this time, there was no army left to stop them.

### `narration_05` — picture: the map, outer walls burning
> The Sea Wall fell first. Then Doran's wall, then Corwin's, then Berin's. Within a week, only one wall still stood. The Last Wall.

### `narration_06` — picture: the king and the hero in the throne room
> The old king did not call for a general. He did not call for an army. There was none left. He called for one soldier, with one shield. "Call the hero."

### `narration_07` — picture: the hero at the Last Wall
> Hold the Last Wall. Take the others back, one by one, all the way to the sea. And whatever they throw at you… bounce it back.

---

## Endings

### `narration_win` — after the flagship sinks
> One by one, the walls were taken back. The great flagship sank beneath the waves, and the sea grew quiet again. Five kings built our walls. One hero brought them home.

### `narration_lose` — when the Last Wall falls
> The Last Wall has fallen. But walls can be rebuilt… and heroes can rise again.

---

## Wall names used in the game (for reference)

| Wall | Name | Built by |
|---|---|---|
| 1 (innermost) | The Last Wall | King Aldren |
| 2 | Berin's Wall | King Berin |
| 3 | Corwin's Wall | King Corwin |
| 4 | Doran's Wall | King Doran |
| 5 (on the shore) | The Sea Wall | King Edmund |
