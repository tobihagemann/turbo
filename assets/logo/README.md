# Turbo Logo

The Thunderbolt lightning hammer, rendered in Blender and enclosed by Apple's native macOS 27 Icon Composer renderer. Open `index.html` to inspect it on light and dark surfaces.

## Files

| File | Purpose |
| --- | --- |
| `thunderbolt.blend` | Editable hammer geometry, materials, lighting, camera, and compositor |
| `thunderbolt.icon` | Editable Icon Composer document, including the transparent Blender artwork |
| `thunderbolt-icon-2048.png` | 2048 × 2048 master with the macOS 27 enclosure |
| `thunderbolt-icon-64.png`, `thunderbolt-icon-128.png`, `thunderbolt-icon-256.png` | Small icons; 128px and 256px also supply 2× display density |
| `build.py`, `render.py`, `export.py` | Model generation, artwork rendering, and native icon exports |

## Construction

The bolt has a bright yellow raised face and amber sloping shoulders to catch metallic reflections. Its face and light channel use parallel offset outlines. The rear perimeter tapers inward to avoid protruding beyond the notch, and the collar covers the upper end of the raised face. Bevels and weighted normals remain editable.

Vents and charge indicators share a baseline; the four fasteners and two striking caps are mirrored. Three lit segments and one dark segment represent partial charge. The clockwise tilt, asymmetric bolt, right-side strike light, and trailing sparks express motion.

The original full-length sparks balance the tilted hammer. The combined silhouette occupies 94% of the artwork canvas's longest dimension. The compositor adds emission-only glow, carried in the artwork's alpha channel; the outer 2% fades smoothly to avoid a hard cutoff.

Icon Composer supplies the charcoal enclosure's exact shape and rim lighting.

The 2048px artwork is placed at 50% on Apple's 1024 × 1024 design canvas with zero translation, preserving its size and position in the 2048px export. Glass effects on the artwork and group translucency are disabled to retain the Blender shading. Generation 27 is explicitly selected during export.

A central radial amber glow sits behind the artwork, independent of the lightning geometry. Separate local bloom comes only from the outer sparks. `export.py` isolates their warm highlights in the outer canvas bands before blurring, so the inner core and bolt seam do not create uneven patches.

The 26 and 27 native enclosure alpha masks were identical in a 2048px comparison. Their lighting differs.

The Blender scene contains only the hammer and studio, with no external font or texture dependencies. The enclosure lives in the Icon Composer document.

## Rendering

Requires Blender 5.2, ImageMagick (`magick` on PATH), and Xcode containing Icon Composer 27 at `/Applications/Xcode.app`.

From this directory, rebuild the model and render its artwork:

```sh
blender --background --factory-startup --python-exit-code 1 --python build.py
blender --background thunderbolt.blend --python-exit-code 1 --python render.py -- 2048 384
```

Building overwrites the Blender file. Rendering writes the 16-bit RGBA artwork into `thunderbolt.icon/Assets/`, then exports the enclosed icon at the requested size.

Arguments are output size (maximum 2048), samples, and optional `CPU` or `METAL` device; defaults are 2048, 384, and Metal.

Every artwork render uses 2048px to keep bloom consistent. The studio uses Cycles, adaptive sampling, denoising, an orthographic camera, and Khronos PBR Neutral color management.

Export all four PNGs from the saved artwork without rerendering Blender:

```sh
python3 export.py
```

Or pass specific sizes, for example `python3 export.py 128 256`. Icon Composer renders the enclosure at 2048px; ImageMagick downsamples with a Mitchell filter in linear RGB to smooth thin highlights and diagonal edges. Intermediate renders are removed automatically.

After rendering, PNGs can be optimized losslessly with ImageOptim, retaining color-management metadata.

## Apple References

- [Icon Composer](https://developer.apple.com/icon-composer/)
- [Creating Your App Icon Using Icon Composer](https://developer.apple.com/documentation/Xcode/creating-your-app-icon-using-icon-composer)
