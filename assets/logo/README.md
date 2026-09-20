# Turbo Logo

The Thunderbolt lightning hammer, rendered in Blender. Open `index.html` to inspect the exports, or open `thunderbolt.blend` in Blender 5.2.

## Files

| File | Purpose |
| --- | --- |
| `thunderbolt.blend` | Editable model, materials, lighting, camera, and compositor |
| `thunderbolt-hero-3200.png` | 3200 × 2000 dark presentation with the **Turbo** wordmark |
| `thunderbolt-dark-2400.png` | 2400 × 2400 close-up with electrical trails |
| `thunderbolt-icon-2400.png` | 2400 × 2400 transparent icon with electrical glow, without floating trails |
| `thunderbolt-icon-64.png`, `thunderbolt-icon-128.png`, `thunderbolt-icon-256.png` | Supersampled small icons; 128px and 256px also supply 2× display density |
| `thunderbolt-readme-light-1440.png`, `thunderbolt-readme-dark-1440.png` | 1440 × 518 transparent README headers with theme-specific wordmarks |
| `build.py`, `render.py` | Model generation and repeatable exports |

## Construction

Bevels and weighted normals remain editable.

The bolt's face, raised inlay, and light channel are offsets of one outline, so corresponding edges remain parallel.

The bolt's rear perimeter tapers inward to prevent its depth from protruding beyond the right-hand notch. Vents and charge indicators share a baseline; the four fasteners and two striking caps are mirrored. Three lit segments and one dark segment represent partial charge. The clockwise tilt, asymmetric bolt, right-side strike light, and trailing sparks express motion.

The **Turbo** wordmark uses Avenir Next Bold Italic outlines, converted to mesh. Materials are procedural. The Blender file has no external font or texture dependencies.

The compositor adds glow from the emission pass only, preserving sharp lettering and metallic highlights. Transparent exports carry the glow in their alpha channel.

The dark square uses an optical vertical offset for balance. Icon framing centers the actual model geometry. Standalone icons occupy 80% of the canvas in their longest dimension, leaving about 10% on each side for breathing room and glow.

The README lockup uses the visible lettering height as its unit: icon height is 2× and the gap from the icon's outer geometry (including sparks) to the lettering is 0.5×. Both are vertically centered. A 0.25em outer margin accommodates glow. Geometry bounds determine the layout.

The hammer's lights move and scale with the assembly to preserve its material finish. Separate lights retain the wordmark's illumination. The light-theme wordmark uses neutral charcoal and white lighting.

## Rendering

From this directory:

```sh
blender --background thunderbolt.blend --python render.py -- hero 3200 384
blender --background thunderbolt.blend --python render.py -- dark 2400 384
blender --background thunderbolt.blend --python render.py -- icon 2400 384
blender --background thunderbolt.blend --python render.py -- icon 64 384
blender --background thunderbolt.blend --python render.py -- icon 128 384
blender --background thunderbolt.blend --python render.py -- icon 256 384
blender --background thunderbolt.blend --python render.py -- readme-light 1440 384
blender --background thunderbolt.blend --python render.py -- readme-dark 1440 384
```

The default device is Metal on macOS. Append `CPU` for CPU rendering. Output files are written next to the Blender file as 16-bit RGBA PNGs; the README headers use 8-bit RGBA for smaller downloads. The studio uses Cycles, adaptive sampling, denoising, an orthographic camera, and Khronos PBR Neutral color management.

Small icons render at a minimum of 512px, and README headers render at twice their export dimensions. The renderer then uses ImageMagick (`magick` on PATH) to downsample the 16-bit intermediate with a Mitchell filter in linear RGB, preserving transparency. This smooths thin highlights and diagonal edges without additional sharpening. Intermediate renders are removed automatically.

After rendering, optimize the PNGs with ImageOptim in lossless mode. Disable PNG metadata stripping to retain color-management information. The checked-in exports preserve the visible rendered colors and alpha values.

To regenerate geometry with `build.py`, first extract face 1 of the macOS `/System/Library/Fonts/Avenir Next.ttc` collection with fontTools into `.turbo/cache/turbo-logo/avenir-next-bold-italic.ttf`. Then run `blender --background --factory-startup --python-exit-code 1 --python assets/logo/build.py` from the repository root. This overwrites the generated Blender file; rendering the existing file requires no font preparation.
