# Interface and transfers — 0.3.5 (build 8)

## Changes

- Negotiations now expose the current stage: read the club reply, agree the club fee, offer personal terms, read the agent reply, then explicitly complete the signing or accept the sale. Reading a reply does not advance fixtures or the calendar. The agreed fee stays fixed during personal terms. Completed deals update the squad and cash once and show a signed confirmation.
- Management pages are inset over their current room. File has a compact panel; negotiations have a bounded layout with stage-specific actions.
- Competition data uses a CRT/teletext presentation with league tables, results, top scorers, form, fixtures, cups, trophies and friendlies. Scorers use recorded season goals across all competitions, filtered by players currently in the selected league; saves do not yet record competition-specific scorer totals.
- Manager, chairman and transfer artwork has been replaced to follow the original room object placements. Data has a new close-up of the original manager room's TV corner. This is a derived viewpoint, not evidence of a distinct original Data room. Business retains the concourse artwork from 0.3.4. Hotspots and toolbar thumbnails follow the new images.
- Stand drafts rebuild their SceneKit preview as capacity, covering, seating and boxes change. Capacity bands are small below 5,000, medium from 5,000, two-tier from 10,000 and three-tier from 15,000. The estate uses the same appearance rules. Roof removal is supported. Quotes and construction times update before commissioning. These thresholds and costs are reconstruction rules, not claimed reverse-engineered original formulas.

## Verification

The isolated interface-035 test career completed a purchase and a sale through native UI controls, including a club counteroffer, personal terms and final acceptance. File and negotiations were visually checked as inset panels; league and top-scorer teletext pages were opened. No main career save was used.

The first stand preview visual check exposed a far-plane clipping problem. Camera near/far planes and framing were corrected. The Mac locked before the final visual recheck of this correction and the new Data artwork, so those final visual checks remain outstanding.

Final verification: 40 scenarios passed, zero failures. Release build and strict deep code-signature verification passed.

Core verification includes direct negotiation replies without calendar advancement, immutable agreed fees, duplicate completion protection, sale acceptance, stand appearance boundaries and roof rules, and scorer/form data. Release package: dist/Ultimate Soccer Manager.app.

## Artwork provenance

Generated with the built-in imagegen tool, 19 September 2026. App assets reside in Sources/USMApp/Resources/Rooms/. Source images are retained under /Users/alisterwood/.codex/generated_images/01a0b712-10a6-7ac2-8d89-4f9149006537/.

- manager-office.png: exec-c93d1815-536c-41f1-a154-97d55178cecd.png
- transfer-office.png: exec-80258f01-5381-4922-accb-21a6877137a6.png
- boardroom.png: exec-fbea9128-8df8-410c-89c1-d561179ae6f0.png
- data-room.png: exec-34b7f27b-b89c-4a17-b91f-774d4b772c20.png

References: original supplied room screenshots, original CD help text, and [original manager room](https://www.mobygames.com/game/568/ultimate-soccer-manager-98/screenshots/windows/218388/). [Teletext reference](https://www.mobygames.com/game/568/ultimate-soccer-manager-98/screenshots/windows/218397/).

### Final generation prompts

Manager:

Create a new high-resolution 16:9 beautifully realistic pre-rendered football management game background recreating this original USM98 manager office EXACT object layout, with modern detailed materials in a nostalgic 1998 English football club. Reference image is composition. Preserve gray filing cabinet far left with open lower drawer, wooden printer cabinet left middle with white laser printer, CRT television atop wooden video/binder rack just left of centre at x48% y48%, potted tall plant centre rear, broad arched stadium-view window on right; wooden desk diagonally fills lower half; white corded desk telephone on left x30% y76%, open newspaper in front centre-left x43% y86%, dark small mobile phone front left x25% y93%, red scrapbook on white blotter centre x64% y78%, open dark laptop on RIGHT x81% y69%, black office chair foreground right. Fixture clipboard on upper left wall x25% y17%, framed team photograph upper centre-right. Clean unobscured full room scene NO popup NO toolbar NO UI labels NO watermark NO people. Warm wood, blue-gray walls, daylight. Keep each interactive object clearly distinguishable. Wide landscape 16:9.

Transfers:

New beautifully realistic high-resolution 16:9 pre-rendered 1998 football management game TRANSFERS ROOM, faithfully preserve original reference composition and functional object placement. Reference screenshot layout only, modern detailed materials consistent with warm wood and natural daylight. Long warm orange-oak conference table fills foreground, blue upholstered chairs along both sides and one at rear. Left wall wide window with horizontal venetian blinds, rear left wooden door, framed red-shirt team photograph rear middle, blank whiteboard on right wall. IMPORTANT clickable objects: large black binoculars standing on table at centre-right x65% y62%; dark green-brown current negotiations folder with papers foreground centre x55% y88%; shortlisted players handwritten paper held at front left x18% y65%; two gray IN/OUT document trays back left of table x35% y44%; tall silver wastepaper bin in rear just right of centre x70% y42%. Mugs and papers back table. Preserve visible foreground hands at left holding shortlist and right holding pen if possible, no faces. No toolbar, popups, captions, UI or watermarks. All key objects clear and separated. Landscape 16:9.

Chairman:

Create polished realistic 16:9 high-resolution pre-rendered football management game CHAIRMAN'S OFFICE from original screenshot reference. Faithfully recreate SAME layout and objects, not a grand boardroom. Exclude all UI toolbar/text outside scene and watermarks. Gray-blue vertically striped wallpaper, blue gray carpet. Left wall small shelf of books at far left, large manager-performance graph white grid with red blue black lines upper left x24% y28%, narrow brass picture light above graph. Small framed plain white objectives note board upper middle-left x43% y32%. Wide stadium-view glass window with horizontal blinds back centre-right x66% y34%, pitch visible. Tall glass trophy cabinet at far RIGHT x91% y47% with gold/silver cups and football trophy. Rich dark reddish wooden desk spans lower left and centre. Newton's cradle front LEFT x10% y72%, large white paper blotter middle-left x33% y72%, desk pen stand mid-left x42% y63%, dark black closed folder middle x43% y70%, beige corded telephone centre x51% y70%. Dark leather chairman chair left behind desk, matching large black leather visitor swivel chair foreground RIGHT x67% y81%. Daylight, attractive material richness, retain original restrained functional composition, no people, no popup, no HUD, no extra computer, landscape16:9.

Data:

Create a beautifully realistic high-resolution 16:9 background for the DATA / SIERRATEXT view of this classic 1998 football management game, using the original manager office reference's television corner and exact objects. Camera has moved closer to the original CRT TV cabinet, not an invented new office. Wide landscape composition: large late-1990s black CRT television centred (outer TV x25%-76%, y12%-69%, blank dark charcoal screen), on warm oak wood cabinet with black VHS player on middle shelf and blue-white binders on lower shelf. Original white printer on its shorter wooden cabinet at far LEFT edge, original tall potted plant on RIGHT edge, gray-blue plaster wall and partial arch of stadium-view window right. Preserve nostalgic 1990s objects but modern detailed realistic rendering, natural daylight and warm wood. TV face nearly front on, subtle realistic rounded glass, visible physical power button and speaker grille below. NO teletext content generated inside screen (code will display data), NO UI toolbar, NO overlay, no captions, no watermark. Landscape16:9. This is a close-up viewpoint of the original reference's TV corner.
