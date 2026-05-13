# Landing Page Generated Assets

Generated landing page assets verified on 2026-05-13.

| Asset | Dimensions | Alpha | Notes |
| --- | ---: | --- | --- |
| `app/assets/images/landing/lp-reference-mock.png` | 932 x 1688 | No | Full-page visual reference mock. Use for comparison only, not as a production page image. |
| `app/assets/images/landing/lp-hero-generated.png` | 1672 x 941 | No | Wide hero background with the bright path concentrated on the left and darker negative space on the right. Suitable for recreating the mock hero with text layered over the darker/controlled areas. |
| `app/assets/images/landing/lp-map-board-generated.png` | 1448 x 1086 | No | Dark mountain valley board background. Suitable behind overlaid roadmap UI, markers, routes, and labels. It has enough detail to support the mock's map-card treatment without needing embedded text in the image. |
| `app/assets/images/landing/lp-cta-generated.png` | 1774 x 887 | No | Wide CTA mountain/path image with strong left-side trail and dark right-side space. Suitable for the final CTA band where copy and buttons need readable contrast. |
| `app/assets/images/landing/compass-mark.png` | 1254 x 1254 | Yes | Transparent RGBA compass mark. Alpha ranges from 0 to 255 with antialiased partial-alpha edge pixels, so it is suitable for logo/icon overlay use. |

## Usage Notes

- The generated scene images are RGB PNGs with no transparent channel. They should be treated as background imagery.
- `compass-mark.png` is the only transparent asset in this set and can be layered over colored or image backgrounds.
- The scene assets are large enough for responsive LP sections and should tolerate cropping for desktop and mobile layouts.
- The hero and CTA assets intentionally reserve dark negative space on the right, matching the mock's need for readable overlaid content.

## Asset Risks

- The generated scene images are dark and atmospheric; overlaid text should use explicit contrast treatment instead of relying on the image alone.
- `compass-mark.png` is high resolution for a small navigation/logo mark. If payload size becomes a concern, consider adding a separately optimized small icon variant later.
