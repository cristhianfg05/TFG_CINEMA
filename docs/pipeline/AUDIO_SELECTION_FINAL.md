# Final selected audio status

This document supersedes earlier candidate-selection notes where they conflict.

## Integrated

- **Footsteps:** `footstep_carpet_303.wav` only, routed through `Player` at
  `-22 dB`; no sample or pitch randomization.
- **Trash pickup:** `trash_pickup_v2_05.wav` only, routed through `Trash` at
  `-18 dB`. It represents litter entering a thin plastic bag.
- **Coin reward:** all `coin_reward_v2_01..05.wav` variants, selected with an
  `AudioStreamRandomizer` on `Trash` with light pitch and level variation.
- **Bin delivery:** all `bin_delivery_01..05.wav` variants, selected with an
  `AudioStreamRandomizer` on `Trash` with light pitch and level variation.

The procedural pickup and empty-tone streams remain as immediate fallback in
the code; they are not deleted legacy assets.

## Approved but not yet integrated

- `bag_full_04.wav`
- `bag_seal_05.wav`
- `bag_throw_04.wav`

## Discarded and removed

- `coin_reward_01..05.wav` (V1 raw, production WAV and derived imports)
- `trash_pickup_01..05.wav` (V1 raw, production WAV and derived imports)
- `footstep_carpet_505.wav` (raw, production WAV and derived import)
