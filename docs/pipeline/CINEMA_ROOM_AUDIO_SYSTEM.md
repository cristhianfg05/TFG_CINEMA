# Cinema room audio system

## Current routing

- `CinemaGlobalMusic` plays the former Room 1 theme from `assets/audio/music/music_room1_03.wav` on the Music bus at -34 dB. It starts after the stand-up intro and loops across the entire cinema.
- `CinemaRoomAudioSystem` owns four instances of `CinemaRoomAudioController`, bound to the large screen speakers and all authored lateral wall speakers in each room.
- Each disabled room plays `assets/audio/ambience/room_radio_static_loop.wav` on two spatial Ambience players at the large speakers. Activation fades that static down and the approved room theme up over 0.7 seconds. Room 2 uses `music_room2_03.wav`, Room 3 uses the approved Action 01 and Room 4 uses the approved Fear 03.
- A separate wall-speaker emitter produces a 0.45–0.85 s interference burst from one randomly chosen lateral speaker every 18–32 s. It is audible only while the player is inside that room and can play softly over the room's music. The same existing static WAV is reused; no new static asset was synthesized.
- The lateral speakers play the room's approved music through individual short-range 3D emitters on the `Music` bus. Room 1 uses the existing `music_room1_03.wav` from the end of the stand-up intro; Rooms 2, 3 and 4 start their approved themes when activated. The same stream feeds large and lateral speakers through this controller.
- Lateral emitter levels are -39 dB for music (raised 3 dB) and -27 dB for occasional interference (raised 2 dB); inverse-distance attenuation, room gating and the 18–32 s interference interval remain unchanged.
- When the player enters an activated room with a movie theme, global music ducks to -48 dB over 1.2 seconds; it recovers on exit. An activated room without its own theme does not duck the global track.

## Activation and future film hook

`GameplayManager.can_activate_room(room_id)` requires that the room be one of the four cinema rooms, have a registered nonzero trash total, have exactly zero remaining items, and not already be active. The existing trash progress dictionaries are authoritative; no new cleanliness counter was introduced. `activate_room()` persists the ID (now save version 9) and emits `room_activated(room_id)`. Room audio and `CinemaMovieController` listen to the same signal; missing video clips leave the screens off. Version 8 saves remain readable.

The manager-office box uses `scenes/props/manager_lever_box.tscn` with four independent raycast hitboxes. Each lever has down/up states, a readiness indicator, a brief lift animation and transient sparks. It cannot be lowered. The player-approved cartoon spark 03 is assigned to `activation_sfx`; four spatial `Machines` voices and per-lever busy states allow rapid activations to overlap without cutting off audio. See [AUDIO_MANAGER_LEVER_CARTOON_SPARK_V2.md](AUDIO_MANAGER_LEVER_CARTOON_SPARK_V2.md).

## New assets and validation

- Source model: `art_source/blender/props/manager_lever_box.blend`.
- Export: `assets/pipeline/props/manager_lever_box.glb`.
- Blender audit: 2,368 triangles, four materials, 2.34 × 0.71 × 1.235 m, four individually pivoted levers, zero degenerate faces and zero open edges after weld.
- Static source and processed loop: `audio_source/raw/sfx/ambience/room_radio_static_01.wav`, `audio_source/generated/sfx/ambience/room_radio_static_full_01.wav`, `assets/audio/ambience/room_radio_static_loop.wav`. Final loop is 5.5 seconds, stereo 44.1 kHz PCM16, with a 0.5-second circular crossfade.
- Approved lever asset: `assets/audio/sfx/machines/manager_lever_cartoon_spark_03.wav`. Older `manager_lever_01`–`03` candidates remain unapproved history; the rejected short-spark 01/02 previews were removed.
- Automated checks: `tests/game_intro_smoke.gd`, `tests/manager_lever_import_smoke.gd`, `tests/manager_lever_overlap_smoke.gd`, `tests/cinema_room_audio_smoke.gd`, `tests/room_02_smoke.gd`.

## Deferred content

Room 1 still has no separate adventure-film theme for its *large* speakers; the existing global/side-wall theme remains. Rooms 3 and 4 use the selections documented in [AUDIO_ROOM3_4_MUSIC_CANDIDATES.md](AUDIO_ROOM3_4_MUSIC_CANDIDATES.md). See `CINEMA_MOVIE_PREPARATION.md` for film clips not yet delivered.
