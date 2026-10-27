extends Node3D
## LOOK TEST - a throwaway dressing spike for Stunt Car Racer VR.
##
## The real game (../game) runs the Compatibility renderer with
## flat-shaded placeholders because every pass so far bought FEEL.
## This scene takes the game's own subjects - the same Odd Rod car
## (part-for-part the game's _build_car layout, same dimensions),
## the same 12 m ribbon on stilts, the same desert floor / hills /
## mesas - and dresses them with Godot 4.7's Forward+ renderer:
## procedural sky at golden hour, a shadow-casting sun, PBR
## materials (clearcoat flake paint, chrome, rubber, vinyl, wood),
## ACES tonemapping, exponential haze, glow, SSAO/SSIL.
##
## There is NO driving. You spawn seated at the game's eye anchor
## and look around; C / controller primary click moves the rig to
## a slow outside orbit so the car can be judged from off-board.
##
## The seat is ANCHORED exactly like the game (Fix Pass 2/3 there):
## a SeatOffset node between the car body and the rig carries a
## rigid correction, applied once the tracked pose is stable, that
## lands the HMD precisely on EYE_ANCHOR - without it the tracked
## seated height stacks on top of the anchor and the driver floats
## a metre over the car (the "high chair"). R / the left
## controller's menu button re-seats (re-arms the anchor).
##
## --lt-lite (user arg) disables SSAO / SSIL / volumetric fog.
## It exists so this scene can be render-captured under software
## Vulkan (SwiftShader) in CI; a real GPU should run it full.

const EYE_ANCHOR: Vector3 = Vector3(0.0, 1.14, 0.05) # the game's, in car space
const WHEEL_LOCALS: Array[Vector2] = [
	Vector2(-0.78, -1.55), Vector2(0.78, -1.55),
	Vector2(-0.78, 1.45), Vector2(0.78, 1.45)] # the game's: 1.56 m track
const HALF_WIDTH: float = 6.0 # 12.0 m road, the game's FP10 width
const RIBBON_DEPTH: float = 0.45 # the game's box section
const DESERT_FLOOR_Y: float = -30.0 # the game's floor, ~60 m under the datum
const TRACK_DATUM_Y: float = 30.0
const CAR_S: float = 38.0 # car parks on the opening straight

var lite_mode: bool = false

var car: Node3D
var car_body: Node3D
var seat_offset: Node3D # child of car_body; carries the anchor correction
var seat_rig: Node3D # child of seat_offset at EYE_ANCHOR; home of the XR origin (cockpit)
var orbit_anchor: Node3D # child of orbit_pivot; the XR origin's outside home
var orbit_pivot: Node3D
var origin: XROrigin3D
var xr_cam: XRCamera3D
var fallback_cam: Camera3D # desktop cockpit camera (car space)
var orbit_cam: Camera3D # desktop outside camera
var xr_active: bool = false
var view_orbit: bool = false
var orbit_angle: float = 0.6
var look_yaw: float = 0.0
var look_pitch: float = 0.0

# Seat anchor, ported from the game (its Fix Pass 2 + 3): the
# correction applies only on a STABLE tracked pose - the camera's
# local position must move less than ANCHOR_STABLE_EPS across
# ANCHOR_STABLE_FRAMES consecutive physics frames. The first valid
# pose off a Virtual Desktop stream can be a transient snapshot;
# anchoring on it would bake a wrong rigid correction for the
# whole session. If no stable pose arrives within
# ANCHOR_FALLBACK_FRAMES (~10 s), apply from whatever pose exists
# and re-apply once when a stable pose later shows up.
const ANCHOR_STABLE_FRAMES: int = 20
const ANCHOR_STABLE_EPS: float = 0.01
const ANCHOR_FALLBACK_FRAMES: int = 600

var anchor_pending: bool = false
var anchor_wait_frames: int = 0
var anchor_state: String = "NONE"
var anchor_stable_frames: int = 0
var anchor_last_cam_pos: Vector3 = Vector3.ZERO
var anchor_have_last: bool = false
var anchor_reapply_watch: bool = false

var env: Environment
var track_frames: Array = [] # Dictionaries: pos, tan, side, up (every 2 m)


# ---------------------------------------------------------------- textures

func _fill_noise(size: int, freq: Vector2, seed_v: int, octaves: int,
		map_fn: Callable) -> Image:
	# map_fn(noise_value -1..1, x, y) -> Color
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.fractal_octaves = octaves
	n.fractal_gain = 0.55
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y: int in size:
		for x: int in size:
			var v: float = n.get_noise_2d(float(x) * freq.x, float(y) * freq.y)
			img.set_pixel(x, y, map_fn.call(v, x, y))
	return img


func _tex(img: Image) -> ImageTexture:
	# Mipmaps are NOT optional: a texture without them is an
	# incomplete texture to the Vulkan renderer, and draws sampling
	# it silently vanish in Forward+ (the Compatibility renderer
	# tolerates it, which is how this bites). Every generated
	# texture in this scene goes through here for that reason.
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _normal_from_height(img: Image, strength: float) -> ImageTexture:
	# Sobel normal map from a grayscale height image (r channel).
	var w: int = img.get_width()
	var h: int = img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y: int in h:
		for x: int in w:
			var tl: float = img.get_pixel((x - 1 + w) % w, (y - 1 + h) % h).r
			var t: float = img.get_pixel(x, (y - 1 + h) % h).r
			var tr: float = img.get_pixel((x + 1) % w, (y - 1 + h) % h).r
			var l: float = img.get_pixel((x - 1 + w) % w, y).r
			var r: float = img.get_pixel((x + 1) % w, y).r
			var bl: float = img.get_pixel((x - 1 + w) % w, (y + 1) % h).r
			var b: float = img.get_pixel(x, (y + 1) % h).r
			var br: float = img.get_pixel((x + 1) % w, (y + 1) % h).r
			var dx: float = (tr + 2.0 * r + br) - (tl + 2.0 * l + bl)
			var dy: float = (bl + 2.0 * b + br) - (tl + 2.0 * t + tr)
			var nrm: Vector3 = Vector3(-dx * strength, dy * strength, 1.0).normalized()
			out.set_pixel(x, y, Color(nrm.x * 0.5 + 0.5, nrm.y * 0.5 + 0.5, nrm.z * 0.5 + 0.5))
	out.generate_mipmaps()
	return ImageTexture.create_from_image(out)


# ---------------------------------------------------------------- materials

var mat_paint: StandardMaterial3D
var mat_chrome: StandardMaterial3D
var mat_steel_dark: StandardMaterial3D
var mat_rubber: StandardMaterial3D
var mat_rim: StandardMaterial3D
var mat_vinyl: StandardMaterial3D
var mat_wood: StandardMaterial3D
var mat_brass: StandardMaterial3D
var mat_asphalt: StandardMaterial3D
var mat_edge_paint: StandardMaterial3D
var mat_skirt: StandardMaterial3D
var mat_underside: StandardMaterial3D
var mat_stilt: StandardMaterial3D
var mat_desert_far: StandardMaterial3D
var mat_desert_near: StandardMaterial3D
var mat_hill: StandardMaterial3D
var mat_mesa: StandardMaterial3D
var mat_mesa_top: StandardMaterial3D
var mat_rock: StandardMaterial3D


func _pbr(albedo: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	return m


func _build_materials() -> void:
	# --- car paint: candy orange-red, metal-flake under clearcoat.
	# The flake lives in the roughness map: a mid-grey base with
	# sparse bright speckles where a flake catches the sun flat
	# (low roughness = hard glint through the coat).
	var flake_img: Image = _fill_noise(256, Vector2(0.9, 0.9), 7101, 1,
		func(v: float, _x: int, _y: int) -> Color:
			var r: float = 0.34 + v * 0.05
			if v > 0.86:
				r = 0.12 # a flake lying flat to the light
			elif v < -0.88:
				r = 0.5 # a flake edge-on
			return Color(r, r, r))
	mat_paint = _pbr(Color(0.78, 0.20, 0.035), 0.72, 1.0)
	mat_paint.roughness_texture = _tex(flake_img)
	mat_paint.clearcoat_enabled = true
	mat_paint.clearcoat = 1.0
	mat_paint.clearcoat_roughness = 0.07

	# --- chrome (blower, stacks, exhausts): near-mirror; the sky
	# does the talking through reflections.
	var chrome_rough: Image = _fill_noise(128, Vector2(0.25, 0.25), 311, 2,
		func(v: float, _x: int, _y: int) -> Color:
			var r: float = 0.13 + v * 0.035
			return Color(r, r, r))
	mat_chrome = _pbr(Color(0.92, 0.94, 0.97), 1.0, 1.0)
	mat_chrome.roughness_texture = _tex(chrome_rough)

	mat_steel_dark = _pbr(Color(0.14, 0.14, 0.16), 0.85, 0.5)
	mat_rim = _pbr(Color(0.52, 0.52, 0.55), 0.9, 0.38)

	# --- rubber: near-black, high roughness, fine grain bump.
	var rubber_h: Image = _fill_noise(128, Vector2(0.8, 0.8), 977, 2,
		func(v: float, _x: int, _y: int) -> Color:
			var g: float = 0.5 + v * 0.5
			return Color(g, g, g))
	mat_rubber = _pbr(Color(0.045, 0.045, 0.05), 0.0, 0.95)
	mat_rubber.normal_enabled = true
	mat_rubber.normal_texture = _normal_from_height(rubber_h, 0.6)
	mat_rubber.normal_scale = 0.35

	# --- vinyl (dash, seat, floor): dark, a whisper of clearcoat
	# sheen so it reads as material, not matte void.
	mat_vinyl = _pbr(Color(0.105, 0.105, 0.115), 0.0, 0.72)
	mat_vinyl.clearcoat_enabled = true
	mat_vinyl.clearcoat = 0.18
	mat_vinyl.clearcoat_roughness = 0.5

	# --- wood wheel rim: warm brown, grain streaked along x.
	var wood_img: Image = _fill_noise(256, Vector2(0.06, 1.4), 4242, 3,
		func(v: float, _x: int, _y: int) -> Color:
			var t: float = 0.5 + v * 0.5
			return Color(0.30 + t * 0.22, 0.17 + t * 0.13, 0.06 + t * 0.05))
	mat_wood = _pbr(Color.WHITE, 0.0, 0.42)
	mat_wood.albedo_texture = _tex(wood_img)
	mat_wood.clearcoat_enabled = true
	mat_wood.clearcoat = 0.5
	mat_wood.clearcoat_roughness = 0.3

	mat_brass = _pbr(Color(0.83, 0.58, 0.18), 1.0, 0.28)

	# --- asphalt: dark aggregate with tonal patches, a speckle
	# roughness and a real normal map so the low sun rakes it.
	var asph_img: Image = _fill_noise(512, Vector2(0.012, 0.012), 5150, 4,
		func(v: float, x: int, y: int) -> Color:
			var g: float = 0.088 + v * 0.02
			# fine aggregate speckle, independent-ish per pixel
			var sp: float = float((x * 73856093) ^ (y * 19349663)) 
			sp = fposmod(sin(sp) * 43758.5453, 1.0)
			g += (sp - 0.5) * 0.07
			return Color(g, g, g * 1.06))
	var asph_h: Image = _fill_noise(256, Vector2(0.35, 0.35), 616, 3,
		func(v: float, _x: int, _y: int) -> Color:
			var g: float = 0.5 + v * 0.5
			return Color(g, g, g))
	mat_asphalt = _pbr(Color.WHITE, 0.0, 0.93)
	mat_asphalt.albedo_texture = _tex(asph_img)
	mat_asphalt.normal_enabled = true
	mat_asphalt.normal_texture = _normal_from_height(asph_h, 1.4)
	mat_asphalt.normal_scale = 0.9
	mat_asphalt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# geometry UVs do the tiling: u 0..1 across the 12 m, v = s/8
	mat_asphalt.texture_repeat = true

	# --- painted edge lines: warm white, scuffed roughness.
	var edge_rough: Image = _fill_noise(256, Vector2(0.05, 0.3), 808, 3,
		func(v: float, _x: int, _y: int) -> Color:
			var r: float = 0.55 + v * 0.22
			return Color(r, r, r))
	mat_edge_paint = _pbr(Color(0.93, 0.91, 0.86), 0.0, 1.0)
	mat_edge_paint.roughness_texture = _tex(edge_rough)
	mat_edge_paint.texture_repeat = true

	# --- skirt: the game's orange, as painted metal.
	mat_skirt = _pbr(Color(0.94, 0.38, 0.03), 0.32, 0.46)
	mat_underside = _pbr(Color(0.36, 0.14, 0.015), 0.2, 0.7)
	mat_stilt = _pbr(Color(0.40, 0.40, 0.44), 0.6, 0.6)

	# --- desert far: one 512 noise stretched over 5 km - broad
	# tonal patches (tens to hundreds of metres), sand to red-brown.
	var far_img: Image = _fill_noise(512, Vector2(0.02, 0.02), 2024, 4,
		func(v: float, _x: int, _y: int) -> Color:
			var t: float = clampf(0.5 + v * 0.62, 0.0, 1.0)
			var lo := Color(0.52, 0.35, 0.20)
			var hi := Color(0.83, 0.68, 0.47)
			return lo.lerp(hi, t))
	mat_desert_far = _pbr(Color.WHITE, 0.0, 1.0)
	mat_desert_far.albedo_texture = _tex(far_img)

	# --- desert near: a tiling grain disc under the track so the
	# ground 60 m below the cockpit still has texture.
	var near_img: Image = _fill_noise(256, Vector2(0.045, 0.045), 909, 3,
		func(v: float, _x: int, _y: int) -> Color:
			var t: float = clampf(0.5 + v * 0.38, 0.0, 1.0)
			var lo := Color(0.58, 0.42, 0.26)
			var hi := Color(0.80, 0.64, 0.44)
			return lo.lerp(hi, t))
	mat_desert_near = _pbr(Color.WHITE, 0.0, 1.0)
	mat_desert_near.albedo_texture = _tex(near_img)
	mat_desert_near.uv1_scale = Vector3(14.0, 14.0, 1.0)
	mat_desert_near.texture_repeat = true

	var hill_img: Image = _fill_noise(128, Vector2(0.08, 0.08), 1212, 3,
		func(v: float, _x: int, _y: int) -> Color:
			var t: float = clampf(0.5 + v * 0.5, 0.0, 1.0)
			return Color(0.50, 0.38, 0.25).lerp(Color(0.66, 0.54, 0.40), t))
	mat_hill = _pbr(Color.WHITE, 0.0, 1.0)
	mat_hill.albedo_texture = _tex(hill_img)
	mat_mesa = _pbr(Color(0.63, 0.44, 0.28), 0.0, 0.96)
	mat_mesa_top = _pbr(Color(0.72, 0.55, 0.36), 0.0, 1.0)
	mat_rock = _pbr(Color(0.40, 0.31, 0.22), 0.0, 0.95)


# ---------------------------------------------------------------- helpers

func _box(parent: Node, size: Vector3, pos: Vector3, mat: Material, bname: String = "") -> MeshInstance3D:
	# the game's own helper, same shape: a BoxMesh instance
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	if bname != "":
		mi.name = bname
	parent.add_child(mi)
	return mi


func _cyl(parent: Node, r_top: float, r_bot: float, height: float, pos: Vector3, mat: Material, sides: int = 24) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = height
	cm.radial_segments = sides
	mi.mesh = cm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


# ---------------------------------------------------------------- environment

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	# Procedural sky, golden hour: warm horizon, deep blue up top,
	# sun disk riding on the directional light's direction.
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.22, 0.40, 0.68)
	sm.sky_horizon_color = Color(0.99, 0.70, 0.44)
	sm.sky_curve = 0.09
	sm.sky_energy_multiplier = 1.0
	sm.ground_bottom_color = Color(0.16, 0.11, 0.08)
	sm.ground_horizon_color = Color(0.88, 0.60, 0.38)
	sm.ground_curve = 0.06
	sm.ground_energy_multiplier = 0.85
	sm.sun_angle_max = 18.0
	sm.sun_curve = 0.06
	sky.sky_material = sm
	sky.process_mode = Sky.PROCESS_MODE_AUTOMATIC
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.background_energy_multiplier = 1.0
	# Image-based light + reflections straight from that sky - this
	# is what makes chrome read as chrome and paint glow.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.85
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.02
	env.tonemap_white = 6.0
	# Exponential haze in warm air: the hills at 600-900 m soften,
	# the ribbon at driving distance stays crisp.
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.94, 0.72, 0.50)
	env.fog_light_energy = 1.0
	env.fog_sun_scatter = 0.38
	env.fog_density = 0.0008
	env.fog_sky_affect = 0.6
	env.fog_height = -20.0
	env.fog_height_density = 0.0
	if not lite_mode:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.012
		env.volumetric_fog_sky_affect = 0.35
		env.ssao_enabled = true
		env.ssao_radius = 1.2
		env.ssao_intensity = 1.6
		env.ssil_enabled = true
		env.ssil_radius = 2.0
		env.ssil_intensity = 0.45
	# Glow: only the sun glints and the gantry lamps should bloom.
	env.glow_enabled = true
	env.glow_intensity = 0.32
	env.glow_strength = 0.9
	env.glow_bloom = 0.06
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.set("glow_levels/1", 0.45)
	env.set("glow_levels/2", 0.3)
	env.set("glow_levels/3", 0.2)
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.04
	env.adjustment_saturation = 1.07
	we.environment = env
	add_child(we)

	# The sun: low, warm, shadow-casting. Elevation ~13 deg puts
	# long shadows across the ribbon - the raking light that makes
	# the asphalt grain and the flake paint work.
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-17.0, -40.0, 0.0)
	sun.light_color = Color(1.0, 0.80, 0.58)
	sun.light_energy = 2.5
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 700.0
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 0.9
	sun.shadow_blur = 1.3
	add_child(sun)


# ---------------------------------------------------------------- desert

func _build_desert() -> void:
	# Far floor: the game's 5 km plane at the game's depth.
	var far := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5000.0, 5000.0)
	far.mesh = pm
	far.position = Vector3(0.0, DESERT_FLOOR_Y, -450.0)
	far.material_override = mat_desert_far
	far.name = "DesertFloorFar"
	add_child(far)
	# Near grain disc under the track (the floor the cockpit
	# actually studies, ~60 m below).
	var near := MeshInstance3D.new()
	var pm2 := PlaneMesh.new()
	pm2.size = Vector2(900.0, 900.0)
	near.mesh = pm2
	near.position = Vector3(0.0, DESERT_FLOOR_Y + 0.03, -180.0)
	near.material_override = mat_desert_near
	near.name = "DesertFloorNear"
	add_child(near)

	# The game's hill ring (same placements/heights), dressed.
	var hills: Array = [
		[Vector2(-620.0, -700.0), 700.0, 46.0, 10.0],
		[Vector2(240.0, -980.0), 820.0, 58.0, -6.0],
		[Vector2(760.0, -420.0), 640.0, 38.0, 24.0],
		[Vector2(680.0, 260.0), 760.0, 42.0, -18.0],
		[Vector2(-40.0, 480.0), 900.0, 34.0, 4.0],
		[Vector2(-780.0, 140.0), 680.0, 50.0, 14.0],
		[Vector2(-420.0, -1320.0), 780.0, 40.0, -10.0],
		[Vector2(420.0, -1420.0), 860.0, 52.0, 8.0],
	]
	for hi: int in hills.size():
		var hd: Array = hills[hi]
		var hxz: Vector2 = hd[0]
		var hill := _box(self, Vector3(float(hd[1]), float(hd[2]), 190.0),
			Vector3(hxz.x, DESERT_FLOOR_Y + float(hd[2]) * 0.32, hxz.y), mat_hill,
			"Hill%d" % hi)
		hill.rotation_degrees.y = float(hd[3])
	# The game's mesas, with a paler cap slab for strata.
	var mesas: Array = [
		[Vector2(-190.0, -260.0), 90.0, 16.0],
		[Vector2(230.0, -520.0), 120.0, 22.0],
		[Vector2(-260.0, -830.0), 105.0, 13.0],
		[Vector2(180.0, -1080.0), 140.0, 19.0],
	]
	for mi2: int in mesas.size():
		var md: Array = mesas[mi2]
		var mxz: Vector2 = md[0]
		var mh: float = float(md[2])
		_box(self, Vector3(float(md[1]), mh, float(md[1]) * 0.62),
			Vector3(mxz.x, DESERT_FLOOR_Y + mh * 0.5, mxz.y), mat_mesa, "Mesa%d" % mi2)
		_box(self, Vector3(float(md[1]) * 1.02, 1.6, float(md[1]) * 0.64),
			Vector3(mxz.x, DESERT_FLOOR_Y + mh + 0.6, mxz.y), mat_mesa_top)

	# Scattered rocks near the track: one MultiMesh, one draw call.
	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 1.0
	rock_mesh.height = 2.0
	rock_mesh.radial_segments = 7
	rock_mesh.rings = 4
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = rock_mesh
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var spots: Array[Transform3D] = []
	while spots.size() < 70:
		var px: float = rng.randf_range(-260.0, 260.0)
		var pz: float = rng.randf_range(-430.0, 60.0)
		# keep the track corridor (|x| < 14 near the straight, and
		# the curve swings to +x later) clear-ish; rocks under the
		# ribbon are fine and read as terrain, inside it are not.
		if absf(px) < 15.0 and pz > -210.0:
			continue
		var sc: float = rng.randf_range(0.35, 2.1)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		basis = basis.scaled(Vector3(sc, sc * rng.randf_range(0.5, 0.8), sc))
		spots.append(Transform3D(basis, Vector3(px, DESERT_FLOOR_Y + sc * 0.2, pz)))
	mm.instance_count = spots.size()
	for i: int in spots.size():
		mm.set_instance_transform(i, spots[i])
		mm.set_instance_color(i, Color(0.5 + rng.randf() * 0.3, 0.52, 0.5))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat_rock
	mmi.name = "Rocks"
	add_child(mmi)


# ---------------------------------------------------------------- the ribbon
# One stretch of the game's ribbon, same construction (12 m box
# section, 0.45 m deep, stilts to the desert floor): an opening
# straight, a ~16 m climb, a crest, and a long banked right curve
# that falls away - enough geography to judge surface, light and
# scale. The car parks at s=38 on the flat.

const TRACK_LEN: float = 400.0

func _elev(s: float) -> float:
	if s < 70.0:
		return TRACK_DATUM_Y
	if s < 160.0:
		return TRACK_DATUM_Y + 16.0 * smoothstep(0.0, 1.0, (s - 70.0) / 90.0)
	if s < 200.0:
		return TRACK_DATUM_Y + 16.0
	if s < 330.0:
		return TRACK_DATUM_Y + 16.0 - 8.0 * smoothstep(0.0, 1.0, (s - 200.0) / 130.0)
	return TRACK_DATUM_Y + 8.0


func _yaw(s: float) -> float:
	if s < 200.0:
		return 0.0
	if s < 330.0:
		return -(s - 200.0) / 80.0 # right-hand arc, R = 80 m
	return -130.0 / 80.0


func _bank_deg(s: float) -> float:
	# positive = rolled about the tangent so the right (inside)
	# edge drops - banking INTO the right curve
	if s < 195.0:
		return 0.0
	if s < 235.0:
		return 30.0 * smoothstep(0.0, 1.0, (s - 195.0) / 40.0)
	if s < 300.0:
		return 30.0
	if s < 340.0:
		return 30.0 * (1.0 - smoothstep(0.0, 1.0, (s - 300.0) / 40.0))
	return 0.0


func _build_track_frames() -> void:
	track_frames.clear()
	var pos := Vector3(0.0, TRACK_DATUM_Y, 0.0)
	var step: float = 1.0
	var s: float = 0.0
	while s <= TRACK_LEN:
		var pitch: float = atan((_elev(s + 1.0) - _elev(s - 1.0)) / 2.0)
		var yaw: float = _yaw(s)
		var hd := Vector3(-sin(yaw), 0.0, -cos(yaw))
		var tan: Vector3 = (hd * cos(pitch) + Vector3.UP * sin(pitch)).normalized()
		var side0: Vector3 = Vector3.UP.cross(tan).normalized() # points LEFT
		var up0: Vector3 = tan.cross(side0).normalized()
		var roll := Basis(tan, deg_to_rad(_bank_deg(s)))
		var f := {
			"pos": pos, "tan": tan,
			"side": (roll * side0).normalized(), "up": (roll * up0).normalized(),
			"s": s,
		}
		if int(round(s)) % 2 == 0:
			track_frames.append(f)
		# advance one step along the slope
		pos += hd * (step * cos(pitch))
		pos.y = _elev(s + step)
		s += step


func frame_at(s: float) -> Dictionary:
	var idx: int = clampi(int(round(s / 2.0)), 0, track_frames.size() - 1)
	return track_frames[idx]


func _quad(pp: PackedVector3Array, nn: PackedVector3Array, uu: PackedVector2Array,
		a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3,
		ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	# tris a-c-b, a-d-c. Winding lesson, learned the hard way:
	# Godot's front face is the one whose winding runs CLOCKWISE
	# in view space, so a quad whose right-hand-rule cross product
	# points AT the viewer is BACK-facing and gets culled. The
	# game's _add_quad order (a-b-c) only works there because the
	# game's frame puts its l0 on the opposite side; in this
	# package's frame (side = LEFT, l0 = p + side*hw) that order
	# renders every ribbon quad inside-out - the surface and the
	# painted edges vanished while the box underside showed
	# through as a fake road. Proven by isolation + a
	# CULL_DISABLED clone lighting the road up magenta.
	for v: Vector3 in [a, c, b, a, d, c]:
		pp.append(v)
		nn.append(n)
	for t: Vector2 in [ua, uc, ub, ua, ud, uc]:
		uu.append(t)


func _mesh_from(pp: PackedVector3Array, nn: PackedVector3Array, uu: PackedVector2Array,
		mat: Material, mname: String) -> MeshInstance3D:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pp
	arrays[Mesh.ARRAY_NORMAL] = nn
	if not uu.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = uu
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = mat
	mi.name = mname
	add_child(mi)
	return mi


func _build_track() -> void:
	_build_track_frames()
	var hw: float = HALF_WIDTH
	var surf_p := PackedVector3Array()
	var surf_n := PackedVector3Array()
	var surf_u := PackedVector2Array()
	var skirt_p := PackedVector3Array()
	var skirt_n := PackedVector3Array()
	var skirt_u := PackedVector2Array()
	var edge_p := PackedVector3Array()
	var edge_n := PackedVector3Array()
	var edge_u := PackedVector2Array()
	var stilt_p := PackedVector3Array()
	var stilt_n := PackedVector3Array()
	var stilt_u := PackedVector2Array()
	for i: int in track_frames.size() - 1:
		var f0: Dictionary = track_frames[i]
		var f1: Dictionary = track_frames[i + 1]
		var p0: Vector3 = f0["pos"]
		var p1: Vector3 = f1["pos"]
		var sd0: Vector3 = f0["side"]
		var sd1: Vector3 = f1["side"]
		var up0: Vector3 = f0["up"]
		var up1: Vector3 = f1["up"]
		var s0: float = f0["s"]
		var s1: float = f1["s"]
		var l0: Vector3 = p0 + sd0 * hw
		var r0: Vector3 = p0 - sd0 * hw
		var l1: Vector3 = p1 + sd1 * hw
		var r1: Vector3 = p1 - sd1 * hw
		var bl0: Vector3 = l0 - up0 * RIBBON_DEPTH
		var br0: Vector3 = r0 - up0 * RIBBON_DEPTH
		var bl1: Vector3 = l1 - up1 * RIBBON_DEPTH
		var br1: Vector3 = r1 - up1 * RIBBON_DEPTH
		var upa: Vector3 = (up0 + up1) * 0.5
		var sda: Vector3 = (sd0 + sd1) * 0.5
		# driving surface
		_quad(surf_p, surf_n, surf_u, l0, r0, r1, l1, upa,
			Vector2(0, s0 / 8.0), Vector2(1, s0 / 8.0), Vector2(1, s1 / 8.0), Vector2(0, s1 / 8.0))
		# box-section skirts + underside
		_quad(skirt_p, skirt_n, skirt_u, l0, l1, bl1, bl0, sda,
			Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		_quad(skirt_p, skirt_n, skirt_u, r1, r0, br0, br1, -sda,
			Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		_quad(skirt_p, skirt_n, skirt_u, bl1, br1, br0, bl0, -upa,
			Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		# painted edge lines, 0.36 m wide at each lip, raised 0.02
		var il0: Vector3 = p0 + sd0 * (hw - 0.5) + up0 * 0.03
		var ol0: Vector3 = l0 + up0 * 0.03
		var il1: Vector3 = p1 + sd1 * (hw - 0.5) + up1 * 0.03
		var ol1: Vector3 = l1 + up1 * 0.03
		_quad(edge_p, edge_n, edge_u, ol0, il0, il1, ol1, upa,
			Vector2(s0 / 8.0, 0), Vector2(s0 / 8.0, 1), Vector2(s1 / 8.0, 1), Vector2(s1 / 8.0, 0))
		var ir0: Vector3 = p0 - sd0 * (hw - 0.5) + up0 * 0.03
		var or0: Vector3 = r0 + up0 * 0.03
		var ir1: Vector3 = p1 - sd1 * (hw - 0.5) + up1 * 0.03
		var or1: Vector3 = r1 + up1 * 0.03
		_quad(edge_p, edge_n, edge_u, ir0, or0, or1, ir1, upa,
			Vector2(s0 / 8.0, 0), Vector2(s0 / 8.0, 1), Vector2(s1 / 8.0, 1), Vector2(s1 / 8.0, 0))
		# stilts every 10 m down to the desert floor
		if int(round(s0)) % 10 == 0:
			# the post starts UNDER the box section: a flush top
			# pokes through the sloped surface beside the
			# centreline and reads as a dark patch on the road
			var top_pt: Vector3 = p0 - up0 * (RIBBON_DEPTH + 0.05)
			var bot := Vector3(top_pt.x, DESERT_FLOOR_Y, top_pt.z)
			_add_stilt(stilt_p, stilt_n, (top_pt + bot) * 0.5, Vector3(0.55, top_pt.y - bot.y, 0.55))
	var no_uv := PackedVector2Array()
	_mesh_from(surf_p, surf_n, surf_u, mat_asphalt, "TrackSurface")
	_mesh_from(skirt_p, skirt_n, skirt_u, mat_skirt, "TrackSkirt")
	_mesh_from(edge_p, edge_n, edge_u, mat_edge_paint, "TrackEdges")
	_mesh_from(stilt_p, stilt_n, no_uv, mat_stilt, "Stilts")
	_build_gantry()


func _add_stilt(pp: PackedVector3Array, nn: PackedVector3Array, center: Vector3, size: Vector3) -> void:
	# axis-aligned box verts (the game's _add_box_verts table)
	var h: Vector3 = size * 0.5
	var corners: Array[Vector3] = []
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				corners.append(center + Vector3(sx * h.x, sy * h.y, sz * h.z))
	var faces: Array = [
		[0, 1, 3, 2, Vector3(-1, 0, 0)], [4, 6, 7, 5, Vector3(1, 0, 0)],
		[0, 4, 5, 1, Vector3(0, -1, 0)], [2, 3, 7, 6, Vector3(0, 1, 0)],
		[0, 2, 6, 4, Vector3(0, 0, -1)], [1, 5, 7, 3, Vector3(0, 0, 1)],
	]
	for f: Array in faces:
		var n: Vector3 = f[4]
		var idxs: Array = [f[0], f[1], f[2], f[0], f[2], f[3]]
		for ix: int in idxs:
			pp.append(corners[ix])
			nn.append(n)


func _build_gantry() -> void:
	# A start gantry 20 m ahead of the parked car: steel posts, a
	# crossbeam, a sign with the working title, four amber lamps
	# (the scene's small glow-earners).
	var f: Dictionary = frame_at(58.0)
	var gp: Vector3 = f["pos"]
	var sd: Vector3 = f["side"]
	var up: Vector3 = f["up"]
	var tan: Vector3 = f["tan"]
	var root := Node3D.new()
	root.name = "Gantry"
	# right-handed basis: x = road-right, y = up, z = back toward
	# the approaching car (so the sign's Label3D faces the driver,
	# unmirrored)
	root.transform = Transform3D(Basis(-sd, up, -tan).orthonormalized(), gp)
	add_child(root)
	_box(root, Vector3(0.32, 5.8, 0.32), Vector3(-(HALF_WIDTH + 0.9), 2.45, 0), mat_steel_dark)
	_box(root, Vector3(0.32, 5.8, 0.32), Vector3(HALF_WIDTH + 0.9, 2.45, 0), mat_steel_dark)
	_box(root, Vector3(2.0 * (HALF_WIDTH + 0.9) + 0.3, 0.35, 0.35), Vector3(0, 5.35, 0), mat_steel_dark)
	var board := _box(root, Vector3(8.6, 1.35, 0.16), Vector3(0, 4.35, 0), mat_vinyl, "SignBoard")
	board.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label := Label3D.new()
	label.text = "DROP START"
	label.font_size = 160
	label.pixel_size = 0.0085
	label.modulate = Color(0.96, 0.93, 0.86)
	label.shaded = true
	label.position = Vector3(0, 4.35, 0.14)
	root.add_child(label)
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1.0, 0.62, 0.10)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.55, 0.06)
	lamp_mat.emission_energy_multiplier = 3.0
	for lx: float in [-3.9, -1.3, 1.3, 3.9]:
		var lamp := MeshInstance3D.new()
		var smesh := SphereMesh.new()
		smesh.radius = 0.09
		smesh.height = 0.18
		lamp.mesh = smesh
		lamp.position = Vector3(lx, 5.05, 0.1)
		lamp.material_override = lamp_mat
		lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(lamp)


func _build_dust() -> void:
	# Golden-hour dust hanging in the air around the parked car:
	# slow motes that catch the light. One particle system, one
	# draw call; if it reads as noise in the captures it goes.
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y: int in 64:
		for x: int in 64:
			var d: float = Vector2(float(x) - 31.5, float(y) - 31.5).length() / 31.5
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 0.9, 0.75, a * a * 0.5))
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(26.0, 4.0, 26.0)
	pmat.direction = Vector3(1.0, 0.12, 0.35)
	pmat.spread = 35.0
	pmat.initial_velocity_min = 0.25
	pmat.initial_velocity_max = 0.7
	pmat.gravity = Vector3(0.0, -0.008, 0.0)
	pmat.damping_min = 0.05
	pmat.damping_max = 0.15
	pmat.scale_min = 0.5
	pmat.scale_max = 1.3
	var quad := QuadMesh.new()
	quad.size = Vector2(0.055, 0.055)
	var qmat := StandardMaterial3D.new()
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	img.generate_mipmaps()
	qmat.albedo_texture = ImageTexture.create_from_image(img)
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = qmat
	var gp := GPUParticles3D.new()
	gp.name = "Dust"
	gp.amount = 220
	gp.lifetime = 8.0
	gp.preprocess = 8.0
	gp.process_material = pmat
	gp.draw_pass_1 = quad
	gp.local_coords = false
	gp.custom_aabb = AABB(Vector3(-60, -15, -60), Vector3(120, 30, 120))
	var cf: Dictionary = frame_at(CAR_S)
	gp.position = (cf["pos"] as Vector3) + Vector3(0.0, 2.2, 0.0)
	add_child(gp)


# ---------------------------------------------------------------- the car
# Part-for-part the game's _build_car / _build_cockpit layout (same
# boxes, same positions - the Odd Rod Chris has been driving),
# re-dressed: flake paint, chrome blower, rubber with grain, steel
# wheel rims, vinyl dash and seat, wood wheel. Two honest additions
# the feel build never needed because the driver IS the seat: a
# seat (so the cockpit reads complete from outside) and exhaust
# tips. Dimensions unchanged: body 1.80 m wide overall, wheel
# track 1.56 m, wheels at the game's WHEEL_LOCALS.

const WHEEL_HUB: Vector3 = Vector3(0.0, 0.88, -0.40) # the game's, car space
const WHEEL_TILT_DEG: float = 22.0 # the game's stood-up wheel

var car_home: Transform3D


func _knob_mat(c: Color) -> StandardMaterial3D:
	var m := _pbr(c, 0.0, 0.3)
	m.clearcoat_enabled = true
	m.clearcoat = 0.6
	m.clearcoat_roughness = 0.25
	return m


func _build_car() -> void:
	var f: Dictionary = frame_at(CAR_S)
	var p: Vector3 = f["pos"]
	var tan: Vector3 = f["tan"]
	var up: Vector3 = f["up"]
	var right: Vector3 = tan.cross(up).normalized()
	car_home = Transform3D(Basis(right, up, -tan).orthonormalized(), p)
	car = Node3D.new()
	car.name = "Car"
	car.transform = car_home
	add_child(car)
	car_body = Node3D.new()
	car_body.name = "Body"
	car.add_child(car_body)

	# Floor + side pods
	_box(car_body, Vector3(1.30, 0.16, 3.30), Vector3(0, 0.32, 0), mat_vinyl)
	_box(car_body, Vector3(0.34, 0.42, 2.60), Vector3(-0.72, 0.48, 0.1), mat_paint)
	_box(car_body, Vector3(0.34, 0.42, 2.60), Vector3(0.72, 0.48, 0.1), mat_paint)
	# Long nose, engine block, chrome blower + intake + stacks
	_box(car_body, Vector3(0.86, 0.34, 1.50), Vector3(0, 0.52, -1.95), mat_paint, "Nose")
	_box(car_body, Vector3(0.62, 0.30, 0.80), Vector3(0, 0.78, -1.85), mat_steel_dark)
	_box(car_body, Vector3(0.30, 0.26, 0.44), Vector3(0, 1.04, -1.85), mat_chrome)
	_box(car_body, Vector3(0.36, 0.05, 0.32), Vector3(0, 1.19, -1.85), mat_steel_dark)
	_box(car_body, Vector3(0.10, 0.20, 0.10), Vector3(-0.28, 1.0, -2.45), mat_chrome)
	_box(car_body, Vector3(0.10, 0.20, 0.10), Vector3(0.28, 1.0, -2.45), mat_chrome)
	# Roll bar + rear deck
	_box(car_body, Vector3(0.08, 0.62, 0.08), Vector3(-0.42, 1.05, 0.78), mat_steel_dark)
	_box(car_body, Vector3(0.08, 0.62, 0.08), Vector3(0.42, 1.05, 0.78), mat_steel_dark)
	_box(car_body, Vector3(0.92, 0.08, 0.08), Vector3(0, 1.36, 0.78), mat_steel_dark)
	_box(car_body, Vector3(1.15, 0.30, 0.85), Vector3(0, 0.52, 1.55), mat_paint)
	# Exhaust tips (addition: the feel build's rear was plain)
	for ex: float in [-0.30, 0.30]:
		var pipe := _cyl(car_body, 0.048, 0.048, 0.42, Vector3(ex, 0.44, 1.98), mat_chrome, 16)
		pipe.rotation_degrees = Vector3(90, 0, 0)
	# The seat (addition: in the game the driver occupies it)
	_box(car_body, Vector3(0.54, 0.10, 0.52), Vector3(0, 0.43, 0.30), mat_vinyl, "SeatBase")
	var sback := _box(car_body, Vector3(0.54, 0.66, 0.11), Vector3(0, 0.80, 0.55), mat_vinyl, "SeatBack")
	sback.rotation_degrees = Vector3(-10, 0, 0)
	_box(car_body, Vector3(0.30, 0.19, 0.10), Vector3(0, 1.22, 0.60), mat_vinyl, "Headrest")
	# Wheels at the game's locals: rubber tyre + steel rim + cap
	for wi: int in WHEEL_LOCALS.size():
		var wl: Vector2 = WHEEL_LOCALS[wi]
		var tyre := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.34
		tm.bottom_radius = 0.34
		tm.height = 0.24
		tm.radial_segments = 28
		tyre.mesh = tm
		tyre.rotation_degrees = Vector3(0, 0, 90)
		tyre.position = Vector3(wl.x, 0.34, wl.y)
		tyre.material_override = mat_rubber
		tyre.name = "WheelF" if wl.y < 0.0 else "WheelR"
		car_body.add_child(tyre)
		var rim := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = 0.20
		rm.bottom_radius = 0.20
		rm.height = 0.25
		rm.radial_segments = 20
		rim.mesh = rm
		rim.rotation_degrees = Vector3(0, 0, 90)
		rim.position = tyre.position
		rim.material_override = mat_rim
		car_body.add_child(rim)
		var cap := MeshInstance3D.new()
		var cm2 := CylinderMesh.new()
		cm2.top_radius = 0.07
		cm2.bottom_radius = 0.07
		cm2.height = 0.26
		cm2.radial_segments = 12
		cap.mesh = cm2
		cap.rotation_degrees = Vector3(0, 0, 90)
		cap.position = tyre.position
		cap.material_override = mat_brass
		car_body.add_child(cap)
	_build_cockpit()


func _build_cockpit() -> void:
	# Dash slab
	_box(car_body, Vector3(1.24, 0.30, 0.14), Vector3(0, 0.78, -0.62), mat_vinyl)
	# Steering column + grab wheel (the game's layout and tilt)
	var tilt_rad: float = deg_to_rad(WHEEL_TILT_DEG)
	var wheel_axis := Vector3(0.0, cos(tilt_rad), sin(tilt_rad))
	var col := _cyl(car_body, 0.03, 0.03, 0.34, WHEEL_HUB - wheel_axis * 0.13, mat_steel_dark, 12)
	col.rotation_degrees = Vector3(WHEEL_TILT_DEG, 0, 0)
	var wheel_node := Node3D.new()
	wheel_node.name = "Wheel"
	wheel_node.position = WHEEL_HUB
	wheel_node.rotation_degrees = Vector3(WHEEL_TILT_DEG, 0, 0)
	car_body.add_child(wheel_node)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.185
	torus.outer_radius = 0.225
	torus.rings = 32
	torus.ring_segments = 12
	rim.mesh = torus
	rim.material_override = mat_wood
	wheel_node.add_child(rim)
	_box(wheel_node, Vector3(0.40, 0.03, 0.045), Vector3(0, 0, 0), mat_rim)
	_box(wheel_node, Vector3(0.045, 0.03, 0.40), Vector3(0, 0, 0), mat_rim)
	var hub := _cyl(wheel_node, 0.055, 0.055, 0.05, Vector3.ZERO, mat_brass, 16)
	hub.rotation_degrees = Vector3(90, 0, 0)
	# Prep switches: the game's three, coloured knobs
	var switch_cols: Array[Color] = [Color(0.9, 0.2, 0.15), Color(0.95, 0.8, 0.15), Color(0.2, 0.5, 0.95)]
	for i: int in 3:
		var piv := Node3D.new()
		piv.position = Vector3(-0.30 + 0.30 * float(i), 0.90, -0.60)
		piv.rotation_degrees = Vector3(-38, 0, 0)
		car_body.add_child(piv)
		_box(piv, Vector3(0.055, 0.20, 0.055), Vector3(0, 0.08, 0), mat_rim)
		_box(piv, Vector3(0.085, 0.06, 0.085), Vector3(0, 0.19, 0), _knob_mat(switch_cols[i]))
	# Dash buttons (static dressing, the game's right-dash row)
	var btn_cols: Array[Color] = [Color(0.85, 0.15, 0.12), Color(0.15, 0.75, 0.3), Color(0.55, 0.3, 0.9)]
	for i: int in 3:
		var b := _cyl(car_body, 0.035, 0.035, 0.03,
			Vector3(0.34 + 0.15 * float(i), 0.945, -0.585), _knob_mat(btn_cols[i]), 16)
		b.rotation_degrees = Vector3(-52, 0, 0)


# ---------------------------------------------------------------- rig & views

var hand_ctrl: Dictionary = {}
var _btn_was: Dictionary = {"L": false, "R": false}
var _menu_was: Dictionary = {"L": false, "R": false}


func _build_rig() -> void:
	# Rig stack: car_body -> SeatOffset -> SeatRig (at EYE_ANCHOR)
	# -> XROrigin. The anchor correction lives on SeatOffset and is
	# never touched by the view toggle; the origin itself stays at
	# zero local transform relative to the rig.
	seat_offset = Node3D.new()
	seat_offset.name = "SeatOffset"
	car_body.add_child(seat_offset)
	seat_rig = Node3D.new()
	seat_rig.name = "SeatRig"
	seat_rig.position = EYE_ANCHOR
	seat_offset.add_child(seat_rig)
	orbit_pivot = Node3D.new()
	orbit_pivot.name = "OrbitPivot"
	orbit_pivot.position = car_home.origin + Vector3(0.0, 0.7, 0.0)
	add_child(orbit_pivot)
	orbit_anchor = Node3D.new()
	orbit_anchor.name = "OrbitAnchor"
	orbit_anchor.position = Vector3(0.0, 0.9, 7.6)
	orbit_pivot.add_child(orbit_anchor)

	origin = XROrigin3D.new()
	origin.name = "Origin"
	seat_rig.add_child(origin)
	xr_cam = XRCamera3D.new()
	xr_cam.near = 0.03
	xr_cam.far = 4000.0
	origin.add_child(xr_cam)
	# Tracker binding per the field census on Chris's rig (Quest 3
	# via Virtual Desktop): plain left_hand/right_hand, pose
	# "default" - the same pattern as the game.
	for hand: String in ["L", "R"]:
		var c := XRController3D.new()
		c.tracker = &"left_hand" if hand == "L" else &"right_hand"
		c.pose = &"default"
		origin.add_child(c)
		hand_ctrl[hand] = c
		var rep := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.026
		sm.height = 0.052
		rep.mesh = sm
		rep.material_override = _pbr(Color(0.1, 0.75, 0.9) if hand == "L" else Color(1.0, 0.55, 0.1), 0.0, 0.4)
		c.add_child(rep)

	fallback_cam = Camera3D.new()
	fallback_cam.name = "FallbackCam"
	fallback_cam.position = EYE_ANCHOR
	fallback_cam.near = 0.03
	fallback_cam.far = 4000.0
	car_body.add_child(fallback_cam)
	orbit_cam = Camera3D.new()
	orbit_cam.name = "OrbitCam"
	orbit_cam.near = 0.05
	orbit_cam.far = 4000.0
	add_child(orbit_cam)

	var xr_interface: XRInterface = XRServer.find_interface("OpenXR")
	if xr_interface != null and xr_interface.initialize():
		get_viewport().use_xr = true
		xr_active = true
		print("LOOKTEST: OpenXR initialized - VR mode")
		_arm_anchor()
	else:
		fallback_cam.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		print("LOOKTEST: no XR runtime - desktop fallback camera")


# ---------------------------------------------------------------- anchor
# Ported from the game (scripts/main.gd there: _arm_anchor,
# _process_anchor_pending, _hmd_has_tracking_data,
# _apply_seat_anchor), minus the lean-neutral capture (no lean
# here) and the panel DIAG reporting (state prints instead).

func _recenter() -> void:
	# Recenter means "put my eye on the cockpit anchor", not the
	# raw XR reference reset (center_on_hmd leaves the tracked
	# seated height stacked on top of the cockpit offset - the
	# driver floated). It just re-arms the stability-gated anchor.
	if xr_active:
		_arm_anchor()


func _arm_anchor() -> void:
	anchor_pending = true
	anchor_wait_frames = 0
	anchor_stable_frames = 0
	anchor_have_last = false
	anchor_reapply_watch = false
	anchor_state = "PENDING"
	print("LOOKTEST: anchor armed")


func _process_anchor_pending() -> void:
	if not xr_active:
		anchor_pending = false
		return
	# Pose stability is tracked continuously (same as the game): a
	# pose counts as stable only after the camera's local position
	# has moved < ANCHOR_STABLE_EPS across ANCHOR_STABLE_FRAMES
	# consecutive physics frames WITH tracking data present.
	if _hmd_has_tracking_data():
		var cam_pos: Vector3 = xr_cam.transform.origin
		if anchor_have_last and cam_pos.distance_to(anchor_last_cam_pos) < ANCHOR_STABLE_EPS:
			anchor_stable_frames += 1
		else:
			anchor_stable_frames = 0
		anchor_last_cam_pos = cam_pos
		anchor_have_last = true
	else:
		anchor_stable_frames = 0
		anchor_have_last = false
	if view_orbit:
		# The correction belongs to the seat stack; while the rig
		# is outside on the orbit anchor an application would be
		# measured against the wrong parent. Stability keeps
		# accruing above; the application lands when the cockpit
		# view returns.
		return
	if anchor_pending:
		anchor_wait_frames += 1
		if anchor_stable_frames >= ANCHOR_STABLE_FRAMES:
			_apply_seat_anchor()
			anchor_state = "APPLIED-STABLE"
			anchor_pending = false
			print("LOOKTEST: anchor APPLIED-STABLE")
		elif anchor_wait_frames > ANCHOR_FALLBACK_FRAMES:
			# ~10 s with no stable pose: apply from whatever pose
			# exists (graceful degradation), but keep watching:
			# when a stable tracked pose later appears, re-apply
			# ONCE from the real pose.
			_apply_seat_anchor()
			anchor_state = "APPLIED-FALLBACK"
			anchor_pending = false
			anchor_reapply_watch = true
			print("LOOKTEST: anchor APPLIED-FALLBACK")
	elif anchor_reapply_watch and anchor_stable_frames >= ANCHOR_STABLE_FRAMES:
		_apply_seat_anchor()
		anchor_state = "APPLIED-STABLE"
		anchor_reapply_watch = false
		print("LOOKTEST: anchor APPLIED-STABLE (re-applied)")


func _hmd_has_tracking_data() -> bool:
	# XRCamera3D has NO tracking query in Godot 4.7: get_is_tracking
	# does not exist anywhere, and get_has_tracking_data is
	# XRNode3D-only - XRCamera3D is not an XRNode3D (the game's
	# Hotfix 1: the wrong call error-spammed every physics frame).
	# Ask the head tracker's pose directly instead.
	var head_tracker: XRTracker = XRServer.get_tracker(&"head")
	if head_tracker == null:
		return false
	var pose_tracker: XRPositionalTracker = head_tracker as XRPositionalTracker
	if pose_tracker == null:
		return false
	var head_pose: XRPose = pose_tracker.get_pose(&"default")
	return head_pose != null and head_pose.has_tracking_data


func _apply_seat_anchor() -> void:
	# Offset the seat so the HMD lands exactly on EYE_ANCHOR in
	# car space, yaw-aligned to the car's heading. The correction
	# is rigid and sits ABOVE the XR origin (on SeatOffset), so
	# head motion afterwards is relative to the anchor. (car_body
	# stands in for the game's car node: its local transform under
	# the car is identity, so car space == car-body space here.)
	var cam_car: Transform3D = car_body.global_transform.affine_inverse() * xr_cam.global_transform
	var fwd: Vector3 = -cam_car.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.05:
		fwd = Vector3(0.0, 0.0, -1.0)
	fwd = fwd.normalized()
	# Yaw that rotates the current horizontal view direction onto
	# the car's forward (-Z in car space).
	var yaw: float = atan2(fwd.z, fwd.x) + PI * 0.5
	var rot := Basis(Vector3.UP, yaw)
	var corr := Transform3D(rot, EYE_ANCHOR - rot * cam_car.origin)
	seat_offset.transform = corr * seat_offset.transform


func _toggle_view() -> void:
	view_orbit = not view_orbit
	if xr_active:
		# move the whole rig: the headset itself goes outside
		if view_orbit:
			seat_rig.remove_child(origin)
			orbit_anchor.add_child(origin)
		else:
			orbit_anchor.remove_child(origin)
			seat_rig.add_child(origin)
		origin.transform = Transform3D.IDENTITY
	else:
		orbit_cam.current = view_orbit
		fallback_cam.current = not view_orbit
	print("LOOKTEST: view = ", "ORBIT" if view_orbit else "COCKPIT")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k: InputEventKey = event
		if k.pressed and not k.echo and (k.keycode == KEY_C or k.keycode == KEY_SPACE):
			_toggle_view()
		if k.pressed and not k.echo and k.keycode == KEY_R:
			_recenter()
		if k.pressed and k.keycode == KEY_ESCAPE and not xr_active:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and not xr_active:
		if (event as InputEventMouseButton).pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and not xr_active and not view_orbit:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var mm: InputEventMouseMotion = event
			look_yaw -= mm.relative.x * 0.0022
			look_pitch = clampf(look_pitch - mm.relative.y * 0.0022, -1.35, 1.35)
			fallback_cam.rotation = Vector3(look_pitch, look_yaw, 0.0)


func _physics_process(_delta: float) -> void:
	_process_anchor_pending()


func _process(delta: float) -> void:
	# controller primary click toggles the view (edge-detected);
	# the menu button re-seats (re-arms the anchor) - the primary
	# click is taken by the view toggle, and on Quest hardware the
	# menu button physically lives on the LEFT controller.
	if xr_active:
		for hand: String in ["L", "R"]:
			var c: XRController3D = hand_ctrl[hand]
			var now: bool = c.is_button_pressed(&"primary_click")
			if now and not bool(_btn_was[hand]):
				_toggle_view()
			_btn_was[hand] = now
			var mnow: bool = c.is_button_pressed(&"menu_button")
			if mnow and not bool(_menu_was[hand]):
				_recenter()
			_menu_was[hand] = mnow
	if view_orbit:
		if xr_active:
			orbit_pivot.rotation.y -= delta * TAU / 80.0
		else:
			orbit_angle += delta * TAU / 80.0
			var centre: Vector3 = car_home.origin + Vector3(0.0, 0.75, 0.0)
			orbit_cam.position = centre + Vector3(sin(orbit_angle) * 8.2, 2.4, cos(orbit_angle) * 8.2)
			orbit_cam.look_at(centre, Vector3.UP)


# ---------------------------------------------------------------- main

func _ready() -> void:
	lite_mode = OS.get_cmdline_user_args().has("--lt-lite")
	_build_materials()
	_build_environment()
	_build_track() # also builds frames + gantry
	_build_desert()
	_build_car()
	_build_rig()
	_build_dust()
	print("LOOKTEST READY (lite=%s, xr=%s) nodes=%d" % [
		str(lite_mode), str(xr_active), _count_nodes(self)])


func _count_nodes(n: Node) -> int:
	var c: int = 1
	for ch: Node in n.get_children():
		c += _count_nodes(ch)
	return c
