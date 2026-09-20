"""Render the studio: blender -b thunderbolt.blend -P render.py -- MODE SIZE SAMPLES [CPU|METAL]."""

import math
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1 :]
mode = args[0] if args else "dark"
size = int(args[1]) if len(args) > 1 else 2400
samples = int(args[2]) if len(args) > 2 else 256
device = args[3] if len(args) > 3 else "METAL"
scene = bpy.data.scenes["Thunderbolt Studio"]
bpy.context.window.scene = scene
camera = scene.camera
root = bpy.data.objects["Thunderbolt · Assembly"]
root.location = (0, 0, 0)
root.scale = (1, 1, 1)
readme = mode in {"readme-light", "readme-dark"}
hero = mode == "hero" or readme
icon = mode == "icon"
transparent = icon or readme
supersample = max(1, math.ceil(512 / size)) if icon else 2 if readme else 1
magick = shutil.which("magick") if supersample > 1 else None
if supersample > 1 and not magick:
    raise RuntimeError(
        "Install ImageMagick to export supersampled icons and README headers."
    )
bpy.data.collections["05 · Speed Trails"].hide_render = icon
bpy.data.collections["06 · Turbo Wordmark"].hide_render = not hero
bpy.data.objects["Backdrop · dark presentation"].hide_render = transparent
camera.data.ortho_scale = 13.4 if hero else 7.3
camera.data.shift_x = 0
camera.data.shift_y = 0 if hero or transparent else 0.05
if readme:
    scene.render.image_settings.color_depth = "8"
    scene.render.image_settings.compression = 75
    if mode == "readme-light":
        wordmark = bpy.data.materials["Turbo · pearl titanium"].node_tree.nodes.get(
            "Principled BSDF"
        )
        wordmark.inputs["Base Color"].default_value = (0.022, 0.022, 0.022, 1)
        wordmark.inputs["Metallic"].default_value = 0.25
        wordmark.inputs["Roughness"].default_value = 0.38


def projected_bounds(objects):
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    camera_inverse = camera.matrix_world.inverted()
    points = []
    for obj in objects:
        if obj.type not in {"MESH", "CURVE"} or obj.hide_render:
            continue
        if any(c.hide_render for c in obj.users_collection):
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        transform = camera_inverse @ evaluated.matrix_world
        points.extend(transform @ v.co for v in mesh.vertices)
        evaluated.to_mesh_clear()
    return (
        min(p.x for p in points),
        min(p.y for p in points),
        max(p.x for p in points),
        max(p.y for p in points),
    )


if icon or readme:
    x0, y0, x1, y1 = projected_bounds(
        [obj for obj in scene.objects if obj.parent == root]
    )
    if icon:
        camera.data.ortho_scale = max(x1 - x0, y1 - y0) / 0.80
        camera.data.shift_x = (x0 + x1) / (2 * camera.data.ortho_scale)
        camera.data.shift_y = (y0 + y1) / (2 * camera.data.ortho_scale)
    else:
        text_obj = bpy.data.objects["Turbo"]
        em = text_obj["em_size"]
        tx0, ty0, tx1, ty1 = projected_bounds([text_obj])
        lettering_height = ty1 - ty0
        icon_height = 2 * lettering_height
        scale = icon_height / (y1 - y0)
        root.scale = (scale, scale, scale)
        offset = Vector(
            (
                tx0 - 0.5 * lettering_height - x1 * scale,
                (ty0 + ty1) / 2 - (y0 + y1) * scale / 2,
                0,
            )
        )
        root.location = camera.rotation_euler.to_quaternion() @ offset
        left = x0 * scale + offset.x
        camera.data.ortho_scale = tx1 - left + 0.5 * em
        camera.data.shift_x = (left + tx1) / (2 * camera.data.ortho_scale)
        camera.data.shift_y = (ty0 + ty1) / (2 * camera.data.ortho_scale)
        readme_aspect = (icon_height + 0.5 * em) / camera.data.ortho_scale
distance = bpy.data.materials[
    "Backdrop · midnight radial gradient"
].node_tree.nodes.get("Vector Math")
distance.inputs[1].default_value = (0.39 if hero else 0.50, 0.52, 0)
if hero:
    if not readme:
        root.location = camera.rotation_euler.to_quaternion() @ Vector((-3.3, 0, 0))
    hammer_receivers = bpy.data.collections.new("Lockup · Hammer Light Receivers")
    wordmark_receivers = bpy.data.collections.new("Lockup · Wordmark Light Receivers")
    wordmark_receivers.objects.link(bpy.data.objects["Turbo"])
    for obj in list(scene.objects):
        if obj.parent == root:
            hammer_receivers.objects.link(obj)
        if obj.type == "LIGHT":
            wordmark_light = obj.copy()
            wordmark_light.name = "Wordmark · " + obj.name
            if mode == "readme-light":
                wordmark_light.data = obj.data.copy()
                wordmark_light.data.color = (1, 1, 1)
            scene.collection.objects.link(wordmark_light)
            wordmark_light.light_linking.receiver_collection = wordmark_receivers
            obj.light_linking.receiver_collection = hammer_receivers
            if readme:
                obj.data = obj.data.copy()
                obj.location *= root.scale.x
                obj.data.energy *= root.scale.x**2
                obj.data.size *= root.scale.x
                obj.data.size_y *= root.scale.x
            obj.location += root.location
scene.render.resolution_x = size
scene.render.resolution_y = (
    round(size * (readme_aspect if readme else 0.625)) if hero else size
)
scene.cycles.samples = samples
scene.cycles.adaptive_threshold = 0.008 if samples >= 256 else 0.025
scene.render.film_transparent = transparent
scene.render.use_compositing = True
prefs = bpy.context.preferences.addons["cycles"].preferences
if device == "METAL":
    prefs.compute_device_type = "METAL"
    prefs.get_devices()
    for item in prefs.devices:
        item.use = item.type == "METAL"
scene.cycles.device = "CPU" if device == "CPU" else "GPU"
output = Path(bpy.data.filepath).parent / f"thunderbolt-{mode}-{size}.png"
if supersample > 1:
    width, height = scene.render.resolution_x, scene.render.resolution_y
    depth = scene.render.image_settings.color_depth
    scene.render.image_settings.color_depth = "16"
    scene.render.resolution_x *= supersample
    scene.render.resolution_y *= supersample
    with tempfile.TemporaryDirectory(prefix="turbo-render-") as temporary:
        source = Path(temporary) / "render.png"
        scene.render.filepath = str(source)
        bpy.ops.render.render(write_still=True)
        subprocess.run(
            [
                magick,
                str(source),
                "-colorspace",
                "RGB",
                "-filter",
                "Mitchell",
                "-resize",
                f"{width}x{height}!",
                "-colorspace",
                "sRGB",
                "-depth",
                depth,
                str(output),
            ],
            check=True,
        )
else:
    scene.render.filepath = str(output)
    bpy.ops.render.render(write_still=True)
