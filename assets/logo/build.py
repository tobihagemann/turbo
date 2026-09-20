"""Build the editable Thunderbolt studio in Blender 5.2."""

import math
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/logo"
FONT = ROOT / ".turbo/cache/turbo-logo/avenir-next-bold-italic.ttf"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.name = "Thunderbolt Studio"


def collection(name):
    value = bpy.data.collections.new(name)
    scene.collection.children.link(value)
    return value


metalwork = collection("01 · Titanium Housing")
handle = collection("02 · Lightning Handle")
electrics = collection("03 · Live Core")
details = collection("04 · Machined Details")
motion = collection("05 · Speed Trails")
wordmark = collection("06 · Turbo Wordmark")
studio = collection("07 · Studio")
root = bpy.data.objects.new("Thunderbolt · Assembly", None)
scene.collection.objects.link(root)
root.rotation_euler.z = math.radians(-13)


def material(name, color, metal=0, rough=0.3, emission=0, texture=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    p = nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value = (*color, 1)
    p.inputs["Metallic"].default_value = metal
    p.inputs["Roughness"].default_value = rough
    p.inputs["Coat Weight"].default_value = 0.22 if metal else 0.1
    p.inputs["Coat Roughness"].default_value = 0.22
    if emission:
        p.inputs["Emission Color"].default_value = (*color, 1)
        p.inputs["Emission Strength"].default_value = emission
    if texture:
        tex = nodes.new("ShaderNodeTexNoise")
        tex.inputs["Scale"].default_value = 240
        tex.inputs["Detail"].default_value = 2
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.045
        bump.inputs["Distance"].default_value = 0.008
        mat.node_tree.links.new(tex.outputs["Fac"], bump.inputs["Height"])
        mat.node_tree.links.new(bump.outputs["Normal"], p.inputs["Normal"])
    return mat


titanium = material(
    "Titanium · satin micrograin", (0.16, 0.30, 0.40), 0.88, 0.265, texture=True
)
polished = material("Titanium · polished chamfers", (0.52, 0.72, 0.88), 0.96, 0.19)
graphite = material("Graphite · ceramic", (0.018, 0.027, 0.038), 0.58, 0.31)
black = material("Recess · carbon black", (0.005, 0.009, 0.015), 0.25, 0.34)
gold = material("Gold · machined alloy", (0.95, 0.32, 0.004), 0.72, 0.24, texture=True)
gold_edge = material("Gold · pale polished bevel", (1, 0.53, 0.018), 0.78, 0.2)
gold_dark = material("Gold · anodized edge", (0.3, 0.105, 0.016), 0.82, 0.27)
energy = material("Amber · charged plasma", (1, 0.30, 0.008), 0.15, 0.22, 6)
white_core = material("Amber · white hot core", (1, 0.65, 0.09), 0.15, 0.2, 4)
soft_energy = material("Amber · running light", (1, 0.38, 0.008), 0.3, 0.26, 3.5)
pearl = material("Turbo · pearl titanium", (0.82, 0.88, 0.94), 0.55, 0.25)


def link(obj, coll, mat=None, parent=root):
    coll.objects.link(obj)
    if mat:
        obj.data.materials.append(mat)
    if parent:
        obj.parent = parent
    return obj


def finish(obj, bevel, segments=4, edge_mat=None):
    if bevel:
        mod = obj.modifiers.new("Precision edge radii", "BEVEL")
        mod.width = bevel
        mod.segments = segments
        if edge_mat:
            obj.data.materials.append(edge_mat)
            mod.affect = "EDGES"
            mod.material = len(obj.data.materials) - 1
    for p in obj.data.polygons:
        p.use_smooth = True
    mod = obj.modifiers.new("Weighted face normals", "WEIGHTED_NORMAL")
    mod.keep_sharp = True
    mod.weight = 50
    return obj


def polygon(
    name, points, back, front, mat, coll, bevel=0.025, edge_mat=None, back_points=None
):
    back_points = back_points if back_points is not None else points
    if (
        sum(
            x * points[(i + 1) % len(points)][1] - points[(i + 1) % len(points)][0] * y
            for i, (x, y) in enumerate(points)
        )
        < 0
    ):
        points = list(reversed(points))
        back_points = list(reversed(back_points))
    n = len(points)
    vertices = [(x, y, back) for x, y in back_points] + [
        (x, y, front) for x, y in points
    ]
    faces = [tuple(reversed(range(n))), tuple(range(n, n * 2))]
    faces.extend((i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    return finish(
        link(bpy.data.objects.new(name, mesh), coll, mat), bevel, edge_mat=edge_mat
    )


def chamfer_rect(cx, cy, w, h, c):
    x0, x1, y0, y1 = cx - w / 2, cx + w / 2, cy - h / 2, cy + h / 2
    return [
        (x0 + c, y0),
        (x1 - c, y0),
        (x1, y0 + c),
        (x1, y1 - c),
        (x1 - c, y1),
        (x0 + c, y1),
        (x0, y1 - c),
        (x0, y0 + c),
    ]


def inset_polygon(points, distance):
    orientation = (
        1
        if sum(
            x * points[(i + 1) % len(points)][1] - points[(i + 1) % len(points)][0] * y
            for i, (x, y) in enumerate(points)
        )
        > 0
        else -1
    )
    edges = []
    for i, point in enumerate(points):
        p = Vector(point)
        direction = (Vector(points[(i + 1) % len(points)]) - p).normalized()
        normal = Vector((-direction.y, direction.x)) * orientation
        edges.append((p + normal * distance, direction))
    inset = []
    for i, (q, f) in enumerate(edges):
        p, e = edges[i - 1]
        delta = q - p
        t = (delta.x * f.y - delta.y * f.x) / (e.x * f.y - e.y * f.x)
        inset.append(tuple(p + e * t))
    return inset


def plate(name, cx, cy, w, h, back, front, mat, coll, chamfer=0.08, bevel=0.02):
    return polygon(
        name, chamfer_rect(cx, cy, w, h, chamfer), back, front, mat, coll, bevel
    )


def frame(name, outer, inner, back, front, mat, coll):
    n = len(outer)
    vertices = [
        (x, y, z) for z in (back, front) for loop in (outer, inner) for x, y in loop
    ]
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces += [
            (i, j, j + 2 * n, i + 2 * n),
            (i + n, i + 3 * n, j + 3 * n, j + n),
            (i + 2 * n, j + 2 * n, j + 3 * n, i + 3 * n),
            (i, i + n, j + n, j),
        ]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    return finish(
        link(bpy.data.objects.new(name, mesh), coll, mat), 0.026, edge_mat=polished
    )


def tube(name, coords, radius, mat, coll, radii=None):
    data = bpy.data.curves.new(name, "CURVE")
    data.dimensions = "3D"
    data.bevel_depth = radius
    data.bevel_resolution = 5
    data.use_fill_caps = True
    data.resolution_u = 16
    spline = data.splines.new("POLY")
    spline.points.add(len(coords) - 1)
    for i, (p, co) in enumerate(zip(spline.points, coords)):
        p.co = (*co, 1)
        if radii:
            p.radius = radii[i]
    return link(bpy.data.objects.new(name, data), coll, mat)


def cylinder(name, xy, z, radius, depth, mat, vertices=64):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth, location=(*xy, z)
    )
    obj = bpy.context.object
    obj.name = name
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    link(obj, details, mat)
    return finish(obj, 0.009, 3)


# Layered head: the bezel is an open ring, so the core sits in a real recess.
outline = chamfer_rect(0, 1.36, 4.05, 1.48, 0.24)
polygon(
    "Forged head · main billet",
    outline,
    -0.39,
    0.27,
    titanium,
    metalwork,
    0.075,
    polished,
)
plate("Rear graphite seam", 0, 1.36, 3.96, 1.4, -0.42, -0.35, graphite, metalwork, 0.22)
frame(
    "Front titanium bezel",
    chamfer_rect(0, 1.36, 3.82, 1.29, 0.17),
    chamfer_rect(0, 1.36, 2.94, 0.73, 0.14),
    0.26,
    0.53,
    titanium,
    metalwork,
)
frame(
    "Inset gasket",
    chamfer_rect(0, 1.36, 3.06, 0.85, 0.15),
    chamfer_rect(0, 1.36, 2.85, 0.65, 0.12),
    0.27,
    0.41,
    graphite,
    metalwork,
)
plate(
    "Chamber · recessed black ceramic",
    0,
    1.36,
    2.9,
    0.71,
    0.27,
    0.31,
    black,
    electrics,
    0.12,
    0.01,
)
for sign in (-1, 1):
    plate(
        "Striking cap " + str(sign),
        sign * 1.89,
        1.36,
        0.39,
        1.37,
        -0.38,
        0.38,
        polished,
        metalwork,
        0.12,
        0.043,
    )
    plate(
        "Cap graphite isolator " + str(sign),
        sign * 1.655,
        1.36,
        0.038,
        1.20,
        -0.36,
        0.43,
        graphite,
        details,
        0.012,
        0.007,
    )
    if sign == 1:
        plate(
            "Strike light · socket",
            1.9,
            1.36,
            0.096,
            0.8,
            0.378,
            0.393,
            black,
            electrics,
            0.04,
            0.012,
        )
        plate(
            "Strike light · amber",
            1.9,
            1.36,
            0.035,
            0.69,
            0.394,
            0.411,
            soft_energy,
            electrics,
            0.013,
            0.008,
        )

for x in (-1.61, 1.61):
    for y in (0.94, 1.78):
        cylinder("Fastener · countersunk socket", (x, y), 0.528, 0.083, 0.012, black)
        cylinder("Fastener · brushed steel", (x, y), 0.541, 0.059, 0.025, polished)
        cylinder("Fastener · hex recess", (x, y), 0.557, 0.028, 0.006, black, 6)

indicator_y = 1.945
for x in (-1.15, -0.97, -0.79):
    plate(
        "Upper micro vent",
        x,
        indicator_y,
        0.095,
        0.022,
        0.506,
        0.533,
        black,
        details,
        0.009,
        0.004,
    )
for i in range(4):
    plate(
        "Charge indicator " + str(i),
        0.75 + i * 0.135,
        indicator_y,
        0.065,
        0.025,
        0.518,
        0.54,
        soft_energy if i < 3 else graphite,
        details,
        0.009,
        0.005,
    )

# The handle is a solid zigzag extrusion, with stepped alloy layers and a light channel.
bolt = [
    (-0.24, 0.79),
    (0.57, 0.79),
    (0.18, -0.20),
    (0.59, -0.20),
    (-0.92, -2.59),
    (-0.52, -1.12),
    (-0.94, -1.12),
    (-0.29, -0.13),
    (-0.55, -0.13),
]
bolt = [(x, 0.70 + (y - 0.70) * 0.88) for x, y in bolt]
polygon(
    "Bolt · dark gold sidewalls",
    bolt,
    -0.26,
    0.18,
    gold_dark,
    handle,
    0.035,
    gold_edge,
    back_points=inset_polygon(bolt, 0.12),
)
polygon(
    "Bolt · gold face",
    inset_polygon(bolt, 0.016),
    0.17,
    0.27,
    gold,
    handle,
    0.014,
    gold_edge,
)
inlay = inset_polygon(bolt, 0.10)
polygon("Bolt · raised pale gold spine", inlay, 0.27, 0.302, gold_edge, handle, 0.017)
plate(
    "Handle · graphite collar",
    0.035,
    0.635,
    0.91,
    0.31,
    -0.30,
    0.34,
    graphite,
    handle,
    0.07,
    0.035,
)
plate(
    "Handle · titanium collar lip",
    0.035,
    0.72,
    0.95,
    0.10,
    -0.31,
    0.36,
    titanium,
    handle,
    0.035,
    0.016,
)
channel = inset_polygon(bolt, 0.20)
channel_start = Vector(channel[1]).lerp(Vector(channel[2]), 0.13)
channel_end = Vector(channel[3]).lerp(Vector(channel[4]), 0.86)
tube(
    "Bolt · charged seam",
    [(x, y, 0.32) for x, y in [channel_start, channel[2], channel[3], channel_end]],
    0.012,
    soft_energy,
    electrics,
)

arc = [
    (-1.25, 1.36, 0.367),
    (-0.38, 1.36, 0.367),
    (-0.60, 1.15, 0.367),
    (0.34, 1.59, 0.367),
    (0.10, 1.36, 0.367),
    (1.25, 1.36, 0.367),
]
tube("Core · amber sheath", arc, 0.028, energy, electrics)
tube(
    "Core · white hot filament",
    [(x, y, z + 0.012) for x, y, z in arc],
    0.010,
    white_core,
    electrics,
)
for x in (-1.31, 1.31):
    cylinder("Core · terminal", (x, 1.36), 0.354, 0.065, 0.09, gold_dark)
    tube(
        "Core · terminal ring",
        [(x, 1.315, 0.406), (x, 1.405, 0.406)],
        0.018,
        gold_edge,
        electrics,
    )

tube(
    "Wake · upper streak",
    [(-3.18, 0.60, 0.02), (-2.68, 0.86, 0.02), (-2.12, 1.13, 0.02)],
    0.015,
    soft_energy,
    motion,
    [0.04, 0.55, 1],
)
tube(
    "Wake · lower streak",
    [(-3.05, 0.14, 0.02), (-2.71, 0.33, 0.02), (-2.25, 0.54, 0.02)],
    0.010,
    gold_edge,
    motion,
    [0.02, 0.7, 1],
)
tube(
    "Wake · electrical snap",
    [
        (-2.79, -0.22, 0.07),
        (-2.08, 0.17, 0.07),
        (-2.22, 0.35, 0.07),
        (-1.66, 0.67, 0.07),
    ],
    0.012,
    energy,
    motion,
    [0.1, 0.9, 0.8, 0.25],
)
tube(
    "Strike · electrical snap",
    [(2.12, 1.96, 0.05), (2.43, 2.18, 0.05), (2.38, 1.88, 0.05), (2.70, 2.10, 0.05)],
    0.011,
    energy,
    motion,
    [0.25, 0.9, 0.85, 0.1],
)


def aim(obj, target):
    obj.rotation_euler = (
        (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
    )


camera_data = bpy.data.cameras.new("Orthographic · Brand Master")
camera = link(
    bpy.data.objects.new("Camera · Brand Master", camera_data), studio, parent=None
)
camera.location = (5, 3.8, 24)
z = camera.location.normalized()
x = Vector((0, 1, 0)).cross(z).normalized()
y = z.cross(x)
camera.rotation_euler = Matrix((x, y, z)).transposed().to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 7.3
camera_data.shift_y = 0.05
camera_data.lens = 70
scene.camera = camera


def area(name, loc, target, color, energy, size, size_y=None):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = energy
    data.color = color
    data.shape = "RECTANGLE"
    data.size = size
    data.size_y = size_y or size
    obj = link(bpy.data.objects.new(name, data), studio, parent=None)
    obj.location = loc
    aim(obj, target)
    return obj


area("Key · tall softbox", (-4, 6, 8), (0, 0, 0), (0.84, 0.93, 1), 1050, 5, 7)
area("Right · edge strip", (5, 1.4, 4), (0, 0, 0), (0.65, 0.8, 1), 850, 2, 6)
area("Top · white ribbon", (0, 6, 1.6), (0, 0, 0), (1, 0.98, 0.93), 1200, 5, 1.2)
area("Warm · gold bounce", (-3, -3, 3), (0, -0.4, 0), (1, 0.59, 0.23), 250, 3, 4)
area("Front · broad fill", (1, -1, 9), (0, 0, 0), (0.88, 0.94, 1), 220, 6)

world = bpy.data.worlds.new("Studio · neutral reflections")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (
    0.15,
    0.19,
    0.25,
    1,
)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.32
scene.world = world

text_data = bpy.data.curves.new("Turbo · original outlined wordmark", "FONT")
text_data.body = "Turbo"
text_data.font = bpy.data.fonts.load(str(FONT))
outline_font = text_data.font
text_data.size = 2.5
text_data.space_character = 0.97
text_data.extrude = 0.018
text_data.bevel_depth = 0.008
text_data.bevel_resolution = 4
text_data.resolution_u = 32
text_obj = link(bpy.data.objects.new("Turbo", text_data), wordmark, pearl, parent=None)
text_obj.parent = camera
text_obj.location = (-0.35, -0.72, -24)
text_obj.scale = (1.4, 1.4, 1.4)
# Blender normalizes this font to its 1695-unit bounds, rather than its 1000-unit em.
text_obj["em_size"] = text_data.size * text_obj.scale.y * 1000 / 1695
bpy.ops.object.select_all(action="DESELECT")
text_obj.select_set(True)
bpy.context.view_layer.objects.active = text_obj
bpy.ops.object.convert(target="MESH")
bpy.data.fonts.remove(outline_font)
wordmark.hide_render = True

backdrop_mat = bpy.data.materials.new("Backdrop · midnight radial gradient")
backdrop_mat.use_nodes = True
nodes = backdrop_mat.node_tree.nodes
nodes.clear()
output = nodes.new("ShaderNodeOutputMaterial")
em = nodes.new("ShaderNodeEmission")
coord = nodes.new("ShaderNodeTexCoord")
dist = nodes.new("ShaderNodeVectorMath")
dist.operation = "DISTANCE"
dist.inputs[1].default_value = (0.50, 0.52, 0)
ramp = nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].position = 0.015
ramp.color_ramp.elements[0].color = (0.045, 0.023, 0.005, 1)
ramp.color_ramp.elements[1].position = 0.22
ramp.color_ramp.elements[1].color = (0.001, 0.002, 0.005, 1)
middle = ramp.color_ramp.elements.new(0.10)
middle.color = (0.007, 0.013, 0.022, 1)
backdrop_mat.node_tree.links.new(coord.outputs["UV"], dist.inputs[0])
backdrop_mat.node_tree.links.new(dist.outputs["Value"], ramp.inputs[0])
backdrop_mat.node_tree.links.new(ramp.outputs[0], em.inputs[0])
backdrop_mat.node_tree.links.new(em.outputs[0], output.inputs[0])
bpy.ops.mesh.primitive_plane_add(size=2)
backdrop = bpy.context.object
backdrop.name = "Backdrop · dark presentation"
for c in list(backdrop.users_collection):
    c.objects.unlink(backdrop)
link(backdrop, studio, backdrop_mat, parent=None)
backdrop.parent = camera
backdrop.location = (0, 0, -29)
backdrop.scale = (15, 15, 15)
backdrop.hide_render = True
backdrop.visible_shadow = False

scene.render.engine = "CYCLES"
scene.cycles.samples = 384
scene.cycles.use_denoising = True
scene.cycles.adaptive_threshold = 0.008
scene.cycles.max_bounces = 10
scene.cycles.transparent_max_bounces = 8
scene.cycles.seed = 17
prefs = bpy.context.preferences.addons["cycles"].preferences
prefs.compute_device_type = "METAL"
prefs.get_devices()
for device in prefs.devices:
    device.use = device.type == "METAL"
scene.cycles.device = "GPU"
scene.render.resolution_x = 2400
scene.render.resolution_y = 2400
scene.render.resolution_percentage = 100
scene.render.film_transparent = False
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.image_settings.color_depth = "16"
scene.render.image_settings.compression = 35
scene.render.filter_size = 1.2
scene.view_settings.view_transform = "Khronos PBR Neutral"
scene.view_settings.look = "None"
scene.view_settings.exposure = -0.4

scene.view_layers[0].use_pass_emit = True
compositor = bpy.data.node_groups.new(
    "Thunderbolt · restrained optical bloom", "CompositorNodeTree"
)
compositor.interface.new_socket(
    name="Image", in_out="OUTPUT", socket_type="NodeSocketColor"
)
layers = compositor.nodes.new("CompositorNodeRLayers")
layers.scene = scene
glow = compositor.nodes.new("CompositorNodeGlare")
glow.inputs["Type"].default_value = "Fog Glow"
glow.inputs["Quality"].default_value = "High"
glow.inputs["Threshold"].default_value = 0.7
glow.inputs["Strength"].default_value = 1.8
glow.inputs["Size"].default_value = 0.40
out = compositor.nodes.new("NodeGroupOutput")
add = compositor.nodes.new("ShaderNodeMixRGB")
add.blend_type = "ADD"
add.inputs[0].default_value = 1
compositor.links.new(layers.outputs["Emission"], glow.inputs["Image"])
compositor.links.new(layers.outputs["Image"], add.inputs[1])
compositor.links.new(glow.outputs["Glare"], add.inputs[2])
separate = compositor.nodes.new("CompositorNodeSeparateColor")
compositor.links.new(glow.outputs["Glare"], separate.inputs["Image"])
alpha = compositor.nodes.new("ShaderNodeMath")
alpha.operation = "ADD"
alpha.use_clamp = True
compositor.links.new(layers.outputs["Alpha"], alpha.inputs[0])
compositor.links.new(separate.outputs["Red"], alpha.inputs[1])
set_alpha = compositor.nodes.new("CompositorNodeSetAlpha")
set_alpha.inputs["Type"].default_value = "Replace Alpha"
compositor.links.new(add.outputs["Color"], set_alpha.inputs["Image"])
compositor.links.new(alpha.outputs[0], set_alpha.inputs["Alpha"])
compositor.links.new(set_alpha.outputs["Image"], out.inputs["Image"])
scene.compositing_node_group = compositor
scene.render.use_compositing = True
motion.hide_render = False
backdrop.hide_render = False
scene.render.filepath = str(OUT / "thunderbolt-dark-2400.png")

for screen in bpy.data.screens:
    for a in screen.areas:
        if a.type == "VIEW_3D":
            a.spaces.active.region_3d.view_perspective = "CAMERA"
            a.spaces.active.overlay.show_overlays = False

scene["Design"] = (
    "Thunderbolt: forged titanium T, recessed amber core, lightning-bolt gold handle."
)
scene["Wordmark"] = "Turbo · original Avenir Next Bold Italic, converted to mesh."
scene["Render variants"] = "icon, dark, hero (see render.py)"
bpy.ops.wm.save_as_mainfile(
    filepath=str(OUT / "thunderbolt.blend"), copy=True, compress=True
)
result = {
    "scene": scene.name,
    "objects": len(scene.objects),
    "file": str(OUT / "thunderbolt.blend"),
}
