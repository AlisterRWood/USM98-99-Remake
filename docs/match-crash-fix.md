# Match crash, 19 September 2026

The crash report `USM98-2026-09-19-181405.ips` ends in SwiftUI runtime access. The preceding unified-log exception at 18:14:01.355 identifies the actionable failure: `-[__NSDictionaryM isPlaying]: unrecognized selector` in `GameAudio.play`, called by `GameStore.tick`. This corresponds to polling and releasing finished audio players inside `effects.removeAll { !$0.isPlaying }`.

Replaced the transient effect array with retained players keyed by sound name. Repeated effects restart their existing player, with a 120ms per-clip retrigger limit. No effect-player isPlaying polling or destruction occurs during event processing. The exact underlying AVFoundation lifetime failure is not established by the log alone.

Validation: four live simulation scenarios passed. `tools/verify-match-audio.swift` runs the actual GameAudio implementation through three complete simulated matches at playback settings 1/8/32: 417 events per match, seven retained sound-effect players, commentary, mute/unmute and cleanup. All passed. These are accelerated stress tests; they do not establish that all possible audio failures are eliminated.

The app was rebuilt and signed as version 0.3.6 (9). Interactive validation uses a separate QA profile to preserve the player's saved career.

Interactive checks passed: toolbar opens original tunnel artwork; a coordinate click on the left door returns to Dressing room; clicking the visible pitch opens live controls; a watched match with sound enabled completed both halves (5–2) and continued to its report; clicking the right door for the next fixture produced an instant full-time result (4–7). No new unrecognized-selector or NSInvalidArgumentException entries appeared in the game log during this check. QA app closed afterward.
