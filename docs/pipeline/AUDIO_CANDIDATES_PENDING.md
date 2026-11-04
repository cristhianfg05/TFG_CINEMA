# Audio candidates pending approval

This manifest is an approval queue only. A candidate is not wired into a scene
or a gameplay script until it has been approved explicitly.

## Integrated and approved

- `assets/audio/sfx/footsteps/footstep_carpet_303.wav`
- `assets/audio/sfx/footsteps/footstep_carpet_505.wav`

These are the two approved carpet-footstep variants. They are randomized by
the player controller and routed to the `Player` bus.

## Priority 1 SFX awaiting group approval

Every family below has five seed variants (`01` through `05`) generated under
`audio_source/raw/sfx/`. After technical processing, their Godot-ready copies
will use the matching folder under `assets/audio/sfx/`.

| Family | Raw source folder | Intended event | Integration state |
| --- | --- | --- | --- |
| `trash_pickup` | `trash/` | Collect a light cinema-trash item | Pending approval |
| `bag_full` | `bags/` | Bag capacity feedback | Pending approval |
| `bag_seal` | `bags/` | Close and tie a full bag | Pending approval |
| `bag_throw` | `bags/` | Release a carried sealed bag | Pending approval |
| `bin_delivery` | `trash/` | Deliver a sealed bag to the bin | Pending approval |
| `coin_reward` | `rewards/` | Coin reward after delivery | Pending approval |

## Music candidates awaiting group approval

Music is assessed as alternatives, so it follows the three-candidate rule in
`cinema-audio-music`, rather than the five-variant SFX rule. These will be
generated after the SFX batch has finished to avoid competing for the local
CPU runtime.

- `music_room1_01` — pending generation
- `music_room1_02` — pending generation
- `music_room1_03` — pending generation

## Explicitly excluded

- No audio is proposed for mechanics that are not implemented.
- Legacy procedural audio remains untouched until a later, specific approval.
