# LP UI implementation plan

## Goal

Recreate the generated LP mock as a Rails + Tailwind/CSS landing page for the Japanese service "ミチシルベ". The page must preserve the mock's dark mountain roadmap tone, Japanese copy, section order, proportions, glowing route motif, and asset treatment as closely as possible in browser-rendered HTML.

Reference mock:

- `/Users/310tea/.codex/generated_images/019e1e60-28f9-72b0-9887-33f1f73ca4d8/ig_09e9fb5bc2dfed8b016a03aea21ac48191bed19652eb04e0f2.png`

Design source:

- `docs/lp_tone_palette_design.md`

## Fidelity Targets

- Desktop target: 1440px wide page should visually match the vertical reference rhythm and relative section heights.
- Header: logo, Japanese nav, and warm gradient CTA must align with the mock.
- Hero: left copy and right app-map panel must appear in the first viewport with the next section slightly visible on common desktop heights.
- Colors: use the LP palette from the design doc as CSS variables.
- Typography: rounded Japanese heading stack and system Japanese sans for body.
- Surfaces: 7-8px radii, thin `Trail Line` borders, subtle glows, no rounded oversized marketing cards.
- Images: image-gen derived scenic assets must be saved into `app/assets/images/landing/` and referenced by Rails helpers.
- Icons: use transparent SVG/CSS icons or transparent PNGs only; do not use opaque icon tiles.
- Animation: add restrained rich motion: route shimmer, node pulse, entrance reveal, CTA hover light, floating pins, and reduced-motion fallbacks.

## Implementation Scope

- `app/views/landing/index.html.erb`
- `app/assets/stylesheets/application.css`
- `app/javascript/application.js` or a small Stimulus controller only if needed
- `app/assets/images/landing/*`

No database, routes, login, user creation, or app-map behavior changes.

## TODO

1. Asset generation
   - Generate a hero scenic background from the mock/reference road imagery.
   - Generate a final CTA road background from the mock/reference road imagery.
   - Generate a clean map-board scenic background for the app preview panel.
   - Keep existing `compass-mark.png` as the transparent brand mark unless a replacement is needed.
   - Store generated files under `app/assets/images/landing/`.

2. Landing markup
   - Rebuild the LP into six sections: hero, problem/concept, flow, setup timeline, final CTA.
   - Encode the exact Japanese copy from the mock/design doc.
   - Use semantic headings, lists, links, and accessible image alt text.
   - Avoid duplicated navigation inside the page because layout nav already owns the header.

3. Visual system
   - Add LP CSS variables for palette.
   - Create page-level layout, fixed transparent nav treatment, section bands, hero grid, app preview, problem split, flow, timeline, final CTA.
   - Match desktop proportions first, then add responsive rules for tablet/mobile.

4. Icons and map UI
   - Build roadmap icons as transparent inline SVG/CSS symbols.
   - Build app preview route and nodes with CSS/SVG overlays so text remains sharp.
   - Use accent colors consistently: value purple, goal blue, subgoal yellow, quest/current green, rewards amber.

5. Animation
   - Add entrance animation for major sections.
   - Add route glow/shimmer and node pulses.
   - Add button hover and subtle preview float.
   - Implement `prefers-reduced-motion` fallback.

6. Verification
   - Run Rails view/assets checks available in the repo.
   - Start local Rails server.
   - Use Browser Use on localhost to inspect desktop and mobile screenshots.
   - Compare against the reference mock for layout, color, text fit, image rendering, and no overlaps.
   - Iterate until the page meets the fidelity target.

## Worker Assignments

- Worker A: owns `app/views/landing/index.html.erb`.
- Worker B: owns LP styling in `app/assets/stylesheets/application.css`.
- Worker C: owns asset placement/reference wiring and icon/visual asset integrity.

Workers are not alone in the codebase. They must not revert edits by others and must adjust their changes to accommodate parallel work.
