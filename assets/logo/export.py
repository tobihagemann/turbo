"""Export the native macOS 27 icon: python3 export.py [SIZE ...]."""

import argparse
import shutil
import subprocess
import tempfile
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("sizes", type=int, nargs="*", default=[64, 128, 256, 2048])
args = parser.parse_args()
if any(not 1 <= size <= 2048 for size in args.sizes):
    parser.error("sizes must be between 1 and 2048 pixels")
directory = Path(__file__).resolve().parent
ictool = Path(
    "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"
)
magick = shutil.which("magick")
if not ictool.is_file() or not magick:
    parser.error("Install Xcode with Icon Composer 27 and ImageMagick to export icons.")

with tempfile.TemporaryDirectory(prefix="turbo-enclosure-") as temporary:
    master = Path(temporary) / "master.png"
    subprocess.run(
        [
            str(ictool),
            str(directory / "thunderbolt.icon"),
            "--export-image",
            "--output-file",
            str(master),
            "--platform",
            "macOS",
            "--rendition",
            "Default",
            "--width",
            "1024",
            "--height",
            "1024",
            "--scale",
            "2",
            "--design-generation",
            "27",
        ],
        check=True,
    )
    for size in args.sizes:
        output = directory / f"thunderbolt-icon-{size}.png"
        if size == 2048:
            shutil.copyfile(master, output)
        else:
            subprocess.run(
                [
                    magick,
                    str(master),
                    "-colorspace",
                    "RGB",
                    "-filter",
                    "Mitchell",
                    "-resize",
                    f"{size}x{size}!",
                    "-colorspace",
                    "sRGB",
                    str(output),
                ],
                check=True,
            )
