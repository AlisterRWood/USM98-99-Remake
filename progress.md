Original prompt: Update the business-office image and interaction so advertising offers open from the top LED board, remove the separate advertising poster, show a blank sponsor window when no shirt sponsor exists, and show the shirt sponsor's company mark when a sponsor is active.

## 2026-09-19

- Replaced `Sources/USMApp/Resources/Rooms/business-office.png` with a cleaned storefront image: removed the far-right advertising placard and replaced the Lotus poster with a blank framed sponsor panel.
- Moved the Business Office advertising hotspot onto the LED sign and renamed it `Advertising LED board`.
- Added runtime commercial overlays in `Sources/USMApp/Rooms.swift`: a pulsing LED indicator when advertising offers are available and a sponsor mark on the window only when an accepted `Club sponsor` deal exists.
- Verified with the rebuilt app: the LED opens Advertising, and an accepted Samsung sponsor renders on the window board. With no accepted club-sponsor deal, the base asset leaves the panel blank.
- `swift build` and `./tools/build-app.sh` completed successfully; only existing Command Line Tools framework search-path warnings were reported.

TODO: none for the requested storefront behavior.

## 2026-09-19

- Corrected stadium stand orientation in `Sources/USMApp/GroundScene.swift` with an explicit facing map for all four sides and four corners; each stand's rear now points away from the pitch.
- Locked the editable ground's camera to its fixed isometric view: dragging no longer orbits, while scroll-wheel and pinch zoom remain available. Updated the on-screen guidance accordingly.
- Verified with `swift test` (compiles successfully; the package currently exposes no discoverable tests) and `./tools/build-app.sh` (production app rebuilt successfully).

TODO: none for the stadium orientation and zoom-only controls.
## 2026-09-20

- Added the multi-agent coordination system: shared cross-worktree file claims, ownership map, workflow/handoff protocol, PR template, CODEOWNERS, macOS CI verification, and `tools/agent-check.sh`.
- Added repository hygiene rules for generated build output and binary assets.
- Smoke-tested claim collision/release and protected-branch rejection.
- Verification: `swift run -c release USMVerify` — 43 scenarios, 0 failures.
