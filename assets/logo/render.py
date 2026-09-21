"""Render the icon: blender -b thunderbolt.blend -P render.py -- SIZE SAMPLES [CPU|METAL]."""

import argparse
import runpy
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import bpy

parser = argparse.ArgumentParser(
    description="Render the Thunderbolt artwork and native macOS enclosure."
)
parser.add_argument("size", type=int, nargs="?", default=2048)
parser.add_argument("samples", type=int, nargs="?", default=384)
parser.add_argument("device", choices=("CPU", "METAL"), nargs="?", default="METAL")
args = parser.parse_args(
    sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
)
if not 1 <= args.size <= 2048:
    parser.error("size must be between 1 and 2048 pixels")
if args.samples < 1:
    parser.error("samples must be positive")
scene = bpy.data.scenes["Thunderbolt Studio"]
bpy.context.window.scene = scene
magick = shutil.which("magick")
if not magick:
    raise RuntimeError("Install ImageMagick to export icons.")
scene.render.resolution_x = 2048
scene.render.resolution_y = 2048
scene.cycles.samples = args.samples
scene.cycles.adaptive_threshold = 0.008 if args.samples >= 256 else 0.025
scene.render.film_transparent = True
scene.render.use_compositing = True
prefs = bpy.context.preferences.addons["cycles"].preferences
if args.device == "METAL":
    prefs.compute_device_type = "METAL"
    prefs.get_devices()
    for item in prefs.devices:
        item.use = item.type == "METAL"
scene.cycles.device = "CPU" if args.device == "CPU" else "GPU"
directory = Path(bpy.data.filepath).parent
output = directory / "thunderbolt.icon/Assets/thunderbolt-icon-2048.png"
scene.render.image_settings.color_depth = "16"
with tempfile.TemporaryDirectory(prefix="turbo-render-") as temporary:
    source = Path(temporary) / "render.png"
    scene.render.filepath = str(source)
    bpy.ops.render.render(write_still=True)
    subprocess.run(
        [
            magick,
            str(source),
            "-channel",
            "A",
            "-fx",
            "edgefade=min(1,min(min(i,w-1-i),min(j,h-1-j))/(w*0.02));a*edgefade*edgefade*(3-2*edgefade)",
            "+channel",
            "-depth",
            "16",
            str(output),
        ],
        check=True,
    )

sys.argv = [str(directory / "export.py"), str(args.size)]
runpy.run_path(sys.argv[0], run_name="__main__")
