# Audio selection update

## Approved selections

- `bag_full_04.wav`
- `bag_seal_05.wav`
- `bag_throw_04.wav`

These three files are approved selections but deliberately remain disconnected
until their gameplay events are integrated one at a time.

## Integrated: bin delivery

`GameplayManager` now uses a `BinDeliveryAudio` player on the `Trash` bus.
It selects randomly from all five `bin_delivery_01..05.wav` files with a small
pitch and level variation. The previous procedural `EmptyAudio` stream remains
in the scene and is retained as a fallback if the new stream is unavailable.

## Regenerated candidates pending approval

- `coin_reward_v2_01..05.wav` are new soft, short coin-collision candidates.
- `trash_pickup_v2_01..05.wav` are new candidates for litter entering a thin
  plastic bag at pickup.

The original `coin_reward_01..05.wav` and `trash_pickup_01..05.wav` are kept
as rejected-reference candidates; no legacy asset was removed or overwritten.
All v2 files are WAV PCM16, stereo, 44.1 kHz and passed technical validation.
