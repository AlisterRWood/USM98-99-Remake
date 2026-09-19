# Usability update 0.3.4 — 19 September 2026

## Delivered

- Individual training shows coach name, speciality and ability in both the selector and current assignment. Speciality now affects training: matching skills use 1.25× quality, other skills 0.65×; workload beyond ten assignments reduces effectiveness proportionally. These are native remake rules, not recovered original formulas.
- Formation Editor and Advanced Tactics share a named save/load/delete library. Saves include formation, custom positions and phase/set-piece instructions, preserve captain/taker choices on load, and persist inside the career save. Names are case-insensitive when replacing a preset.
- Right-click in club management returns to the room; right-click in a room returns to the stadium. Player records dismiss on right-click. In squad selection, right-click on the player-name column still picks up the player; right-click elsewhere goes back. Redundant top back strips removed; explicit Exit buttons remain accessible.
- Stadium starts closer, zoom is clamped to orthographic scales 65–135, and drag orbits a fixed centre instead of allowing a pan into empty space. Permanent streets and terraced housing surround the editable ground. All existing building placement and upgrades remain live geometry. Shared materials prevent SceneKit's flattened-town material overflow.
- Ribbon uses evenly sized FILE / STAD / BUSI / CHAIR / DATA / TRANS / MNGR / SQUAD / MATCH / HELP tiles, followed by a separate calendar. MATCH is an illustrated tunnel tile.
- Business background follows the original concourse/shop frontage: burger cart left, accounts door and shop inside, ticket counter centre, sponsorship board right, advertising board far right. All six hotspots mapped to their visible objects.
- Own players cannot be added to the shortlist; own-player records expose transfer asking price, loan listing and fast sale. Ordinary transfer/loan offers appear in Negotiations and require acceptance. Fast sale pays 60% of current valuation immediately, moves the player to another club, clears listings/assignments/tactical references and repairs team selection. It requires an explicit second in-game confirmation.
- Borrowed players cannot be sold; no release can leave fewer than 16 players or occur during an active match. Outgoing loans return after their agreed term. New optional save fields preserve compatibility with older careers.

## Verification

- `swift run -c release USMVerify`: 37 scenarios, zero failures, after final core changes.
- Named formation round trip, complete positions/plan restoration, case-insensitive replacement and deletion.
- Own-player shortlist rejection, asking-price/loan persistence, immediate cash settlement, no duplicate sale, outgoing loan return, borrowed-player protection and minimum squad size.
- Full existing season, player development, match, finance and transfer regression suite.
- Native UI checked in an isolated QA career: named formation save/load feedback; coach appointment and assignment label; sponsorship hotspot and return; player-name pickup and right-click back; player record market layout, transfer listing status and right-click dismissal; stadium rendering, both zoom limits and orbit.
- `tools/build-app.sh`: release build and ad-hoc signature verification passed. Main career save untouched by QA.

## Business-room asset provenance

Reference: [original USM98 business room screenshot](https://www.mobygames.com/game/568/ultimate-soccer-manager-98/screenshots/windows/218387/), image `https://cdn.mobygames.com/screenshots/10667838-ultimate-soccer-manager-98-windows-the-business-room.png`.

Generated with the built-in imagegen tool using the imagegen skill, then saved to `Sources/USMApp/Resources/Rooms/business-office.png`. This is a new rendering based on the original layout, not an extracted original background or a pixel-identical reproduction.

Final prompt:

> Create a beautiful high-resolution 16:9 game room background faithfully recreating the layout in this original Ultimate Soccer Manager business-room reference. Reference is composition/layout, upgrade materials and rendering to polished realistic 1990s football stadium game art. No UI chrome or overlays. Full scene: brick stadium concourse storefront with large glazed entrance, dark blue canopy and FOOTBALL CLUB round football crest above. At left foreground a small red-white awning burger cart with JOE'S BURGERS and a menu. Through central opening, back left small wooden door with ACCOUNTS sign above, central rear wall club merchandise display with SHOP sign, middle lower ticket counter TICKETS AVAILABLE HERE. Right glass pane prominently carries framed sponsorship logo board Lotus Working Together, separate far-right brick wall has an ADVERTISING board fully visible. Preserve relative original object positions but widen composition to 16:9 and clearly separate all six clickable objects (burger cart, accounts door, shop display, ticket counter, sponsorship board, advertising board). Warm brick, blue framing, natural stadium daylight, realistic texture detail, inviting slightly nostalgic cinematic pre-rendered game scene. No people, no office desk, no computer, no folders. Output landscape 1536x864 or 16:9.
