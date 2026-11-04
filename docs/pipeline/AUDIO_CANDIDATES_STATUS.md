# Audio candidates: technical status

This addendum supersedes the generation-status wording in
`AUDIO_CANDIDATES_PENDING.md`.

## Pending group approval

Thirty Priority 1 SFX candidates are generated, processed and technically
valid. Each family has variants `01` through `05` in both its raw source and
Godot-ready destination:

- `trash_pickup` — `audio_source/raw/sfx/trash/`, `assets/audio/sfx/trash/`
- `bag_full`, `bag_seal`, `bag_throw` — `audio_source/raw/sfx/bags/`,
  `assets/audio/sfx/bags/`
- `bin_delivery` — `audio_source/raw/sfx/trash/`, `assets/audio/sfx/trash/`
- `coin_reward` — `audio_source/raw/sfx/rewards/`,
  `assets/audio/sfx/rewards/`

They are PCM16, 44.1 kHz, stereo; technical validation found no clipping or
silence failure. They are deliberately not referenced by gameplay yet.

## Music proposals pending group approval

| Candidate | Godot-ready duration | Status |
| --- | ---: | --- |
| `music_room1_01` | 8.201 s | Preview only; do not approve as a production loop without a replacement or loop pass. |
| `music_room1_02` | 19.245 s | Pending approval. |
| `music_room1_03` | 19.253 s | Pending approval. |

All three are PCM16, 44.1 kHz, stereo and not connected to the Music bus.

## Already approved and integrated

- `footstep_carpet_303.wav`
- `footstep_carpet_505.wav`

Only these two variants are in use by the player controller, routed to the
`Player` bus. Legacy audio remains untouched.
