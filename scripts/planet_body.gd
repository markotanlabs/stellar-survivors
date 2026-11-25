extends ColorRect
## A planet or gas giant as a spinning pixel-art sphere, in the style of Deep-Fold's
## Pixel Planet Generator: noise land and seas, drifting clouds, polar caps, dithered
## light bands lit from the system's centre, and a glowing atmosphere rim.
## One shader, several looks: terran, desert, rocky (dead), molten, gas giant and ice.

const GD = preload("res://scripts/game_data.gd")

const TERRAN := 0
const DESERT := 1
const ROCKY := 2
const GAS := 3
const ICE := 4
const EARTH := 5   # the real Earth: continents from EARTH_MAP

## Earth's real coastlines and terrain, 128 x 64, longitude -180..180 left to right,
## latitude 90..-90 top to bottom. . ocean, g grassland, f rainforest, d desert,
## t northern/southern lands (tundra, taiga, steppe), i ice.
const EARTH_MAP := [
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"......................................iiiiiiiiiiiiiiiiii............iiiiii......................................................",
	"........................................iiiiiiiiiiiiiiiii......................................iiiiiiiii........................",
	"...................ttttttttttttttttttttt..iiiiiiiiiiiiii.................................tttttttttttttttttttttttttt.............",
	"......ttttttttttttttttttttttttttttttttttt...iiiiiiiiiii..............tttttttt....tttttttttttttttttttttttttttttttttttttttttttt...",
	"....tttttttttttttttttttttttttttttttttttttt...iiiiiii................tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
	".....ttttttttttttttttttttttttttttttttttttt....ii..................tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
	".....tttttttttttttttttttttttttttttttttttttt.......................ttttttttttttttttttttttttttttttttttttttttttttttttttttttttt.....",
	"................ggggggggggggggggggggggggggg...................g....gggggggggggggggggggggggggggggggggggggggggggggggggggg.........",
	".................ggggggggggggggggggggggggggg.................ggg..ggggggggggggggggggggggggggggggggggggggggggggggggggg...........",
	"..................gggggggggggggggggggggggggg................ggggggggggggggggggggggggggggggggggggggggggggggggggggggg.............",
	"...................gggggggggggggggggggggggg....................ggggggggggggggggggggggggggggggggggggggggggggggggggg..............",
	"....................ggggggggggggggggggggg......................ggggggggggggggggggggggggggggggggggggggggggggggggggg..............",
	"....................gggggggggggggggggggg......................gggg...gggggggggggggggggggggggggggdddddddddgggggg.................",
	"....................ggggggggggggggggggg......................gggg.....ggggggggggggggggggggggggggdddddddddggggg...g..............",
	".....................ggggggggggggggggg.......................ggg........g.ggggggggdddddddgggggggggggggggggg......g..............",
	"......................dddddgggggggggg.........................gggggg.........gggggdddddddgggggggggggggggggg.....g...............",
	".......................ddddggggggggg.........................gggggggggg.....ggggggdddddddgggggggggggggggggg.....................",
	".......................ddddgggggggg.........................ddddddddddddddddggdddddddddddgggggggggggggggggg.....................",
	"........................gggggg..............................dddddddddddddddd.gdddddddddddgggggggggggggggggg.....................",
	".........................ggggg.............................dddddddddddddddddggdddddd....gggggggggggggggggg......................",
	"..........................gggg............................gdddddddddddddddddg.dddddd.....ggggggggggggggg........................",
	"............................ggg...........................gdddddddddddddddddg..dddd.......gggg...gfffff.........................",
	"...............................g..........................gdddddddddddddddddggdddd........ggg.....ffff.....g....................",
	".................................f........................ggggggggggggggggggggg............g......ffff.....g....................",
	"..................................f..ggggg.................ggggggggggggggggggggggg.........g...............g....................",
	"....................................ggggggg................gggggggggggggggggggggg...........g..............gg...................",
	"....................................gfffffff.................g....ggfffffffggggg..................f.....ff......................",
	"....................................gfffffffff.....................gfffffffggggg...................f...fff......................",
	"...................................ggfffffffffg.....................fffffffgggg........................fff......................",
	"...................................ggfffffffffgggg..................fffffffggg......................f...........ggg.............",
	"....................................gfffffffffggggg.................gggggggggg........................ggg........ggg............",
	"....................................gfffffffffggggg.................gggggggggg..................................................",
	".....................................gggggggggggggg..................ggggggggg...............................gggggg.............",
	"......................................gggggggggggg..................gggggggggg..gg..........................ggggggg.............",
	".......................................gggggggggg...................ggggggggg...g..........................ddddddddd............",
	".......................................gggggggggg....................gdddgggg...g........................ggdddddddddg...........",
	".......................................ggggggggg.....................gdddggg....g........................ggdddddddddgg..........",
	".......................................gggggggg......................gdddggg.............................ggdddddddddgg..........",
	".......................................ggggggg........................ggggg..............................ggdddddddddgg..........",
	".......................................gggggg.........................gggg...............................gggg.gggggggg..........",
	"......................................gggggg.....................................................................ggggg.......g..",
	"......................................ggggg........................................................................gg........gg.",
	"......................................gggg...................................................................................g..",
	"......................................ggg...................................................................................g...",
	"......................................gg........................................................................................",
	"......................................tt........................................................................................",
	"................................................................................................................................",
	"................................................................................................................................",
	"................................................................................................................................",
	"................................................................................................................................",
	"................................................................................................................................",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
	"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii",
]
const EARTH_COLOURS := {".": Color(0, 0, 0, 0), "g": Color("4f8a3a"), "f": Color("2f6a2e"), "d": Color("d2b77a"), "t": Color("7f8f5a"), "i": Color("eef2f6")}
static var _earth_texture: ImageTexture = null

const SHADER := """
shader_type canvas_item;

uniform float pixels = 96.0;
uniform float spin = 0.03;
uniform float seed = 1.0;
uniform vec2 light_dir = vec2(-0.5, -0.4);
uniform int mode = 0;
uniform vec4 c_deep : source_color;
uniform vec4 c_sea : source_color;
uniform vec4 c_land1 : source_color;
uniform vec4 c_land2 : source_color;
uniform vec4 c_land3 : source_color;
uniform vec4 c_cloud : source_color;
uniform vec4 c_atmo : source_color;
uniform float land_level = 0.5;
uniform float cloud_cover = 0.4;
uniform sampler2D earth_map : filter_nearest, repeat_enable;

float hash3(vec3 p) {
	vec3 q = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	q *= 17.0;
	return fract(q.x * q.y * q.z * (q.x + q.y + q.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i + vec3(0.0, 0.0, 0.0)), hash3(i + vec3(1.0, 0.0, 0.0)), f.x),
				   mix(hash3(i + vec3(0.0, 1.0, 0.0)), hash3(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
			   mix(mix(hash3(i + vec3(0.0, 0.0, 1.0)), hash3(i + vec3(1.0, 0.0, 1.0)), f.x),
				   mix(hash3(i + vec3(0.0, 1.0, 1.0)), hash3(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	vec3 q = p;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(q);
		q *= 2.02;
		a *= 0.5;
	}
	return v;
}

vec3 rot_y(vec3 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
}

void fragment() {
	// Snap to a coarse pixel grid for the pixel-art look.
	vec2 cell = floor(UV * pixels);
	vec2 uv = (cell + 0.5) / pixels;
	vec2 p = (uv * 2.0 - 1.0) / 0.8;
	float d = length(p);
	vec3 l = normalize(vec3(light_dir, 0.55));
	if (d > 1.0) {
		// Atmosphere: a soft rim, brighter on the sunlit side.
		float a = smoothstep(1.14, 1.0, d) * c_atmo.a;
		float side = clamp(dot(normalize(vec3(p, 0.0)), l) * 0.5 + 0.6, 0.15, 1.0);
		COLOR = vec4(c_atmo.rgb, a * side);
	} else {
		float z = sqrt(1.0 - d * d);
		vec3 n = vec3(p.x, p.y, z);
		vec3 sp = rot_y(n, TIME * spin + seed);
		float lit = dot(n, l);
		// Light in four dithered bands, like hand-shaded pixel art.
		float dither = mod(cell.x + cell.y, 2.0) * 0.12;
		float band = clamp(floor((lit * 0.5 + 0.5) * 4.0 + dither) / 4.0, 0.0, 1.0);
		float shade = mix(0.12, 1.1, band);
		vec3 col;
		if (mode == 3) {
			// Gas giant: wavy bands with turbulence and a few storms.
			float turb = fbm(sp * vec3(2.0, 6.0, 2.0) + vec3(TIME * spin * 2.0, 0.0, 0.0) + seed);
			float k = 0.5 + 0.5 * sin((sp.y * 5.0 + turb * 1.6) * 3.14159);
			col = mix(c_land1.rgb, c_land2.rgb, k);
			col = mix(col, c_land3.rgb, smoothstep(0.62, 0.8, fbm(sp * 4.0 + seed + TIME * 0.02)));
		} else {
			float h = fbm(sp * 2.2 + seed * 3.7);
			if (mode == 5) {
				// The real Earth: look its continents up on the world map by longitude/latitude.
				float lon = atan(sp.x, sp.z);
				float lat = asin(clamp(-sp.y, -1.0, 1.0));
				vec4 m = texture(earth_map, vec2(lon / 6.28318 + 0.5, 0.5 - lat / 3.14159));
				if (m.a < 0.5) {
					col = mix(c_deep.rgb, c_sea.rgb, smoothstep(0.3, 0.7, h));
				} else {
					col = m.rgb * (0.9 + 0.2 * h);
				}
			} else if (mode == 2) {
				// Rocky and dead: dusty patches and craters.
				col = mix(c_land1.rgb, c_land2.rgb, smoothstep(0.35, 0.65, h));
				col = mix(col, c_land3.rgb, step(0.66, fbm(sp * 6.0 + seed)));
			} else if (h < land_level) {
				col = mix(c_deep.rgb, c_sea.rgb, smoothstep(land_level - 0.18, land_level, h));
			} else {
				float lh = (h - land_level) / max(1.0 - land_level, 0.01);
				col = lh < 0.18 ? c_land1.rgb : (lh < 0.42 ? c_land2.rgb : c_land3.rgb);
			}
			// Polar caps on terran and ice worlds.
			if (mode == 0 || mode == 4) {
				float cap = step(0.86 - h * 0.12, abs(n.y));
				col = mix(col, c_cloud.rgb, cap * (mode == 4 ? 1.0 : 0.85));
			}
		}
		col *= shade;
		// Clouds drift a little faster than the ground.
		if ((mode == 0 || mode == 1 || mode == 4 || mode == 5) && cloud_cover > 0.0) {
			vec3 cp = rot_y(n, TIME * spin * 1.6 + seed + 1.0);
			float cl = fbm(cp * vec3(3.0, 5.0, 3.0) + vec3(TIME * 0.03, 0.0, 0.0));
			if (cl > 1.0 - cloud_cover * 0.9) {
				col = c_cloud.rgb * mix(0.35, 1.05, band);
			}
		}
		// A one-pixel dark edge.
		if (d > 1.0 - 2.0 / pixels / 0.8) {
			col *= 0.55;
		}
		COLOR = vec4(col, 1.0);
	}
}
"""

static var _shader: Shader = null

var body: Dictionary = {}       # the planet or gas giant's data
var giant := false
var _look_key := ""
var _mat: ShaderMaterial = null
var _pic: TextureRect = null
var _look_timer := 0.0


## Performance: the shader runs once per planet *pixel* (180 or 240 square) in a small
## off-screen viewport, and the result is scaled up crisp (nearest filter). Running it
## per screen pixel over a planet 1000+ px wide was the most expensive thing on screen.
func setup(new_body: Dictionary, is_giant: bool) -> void:
	body = new_body
	giant = is_giant
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(0, 0, 0, 0)   # this rect is just the frame; the picture is the child below
	var r := float(body["radius"]) * GD.UNIT
	var half := r / 0.8   # the sphere fills 80% of the square; the rest is atmosphere
	size = Vector2(half, half) * 2.0
	position = Vector2(body["pos"]) * GD.UNIT - size / 2.0
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	var px := 240 if giant else 180
	var vp := SubViewport.new()
	vp.size = Vector2i(px, px)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(vp)
	var canvas := ColorRect.new()
	canvas.color = Color.WHITE
	canvas.size = Vector2(px, px)
	canvas.material = _mat
	vp.add_child(canvas)
	var pic := TextureRect.new()
	_pic = pic
	pic.texture = vp.get_texture()
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pic)
	# Lit from the system's centre.
	var pos: Vector2 = body["pos"]
	var to_sun := -pos.normalized() if pos.length() > 0.1 else Vector2(-0.6, -0.5)
	_mat.set_shader_parameter("light_dir", to_sun)
	_mat.set_shader_parameter("pixels", float(px))
	_mat.set_shader_parameter("seed", fmod(absf(pos.x * 0.37 + pos.y * 0.71), 50.0) + 1.0)
	_mat.set_shader_parameter("spin", 0.02 if giant else 0.035)
	_apply_look()


## Small globes (a planet window's header): filter smoothly so the pixel grid
## doesn't shimmer when 180 pixels are squeezed into a few dozen.
func smooth() -> void:
	if _pic != null:
		_pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _process(delta: float) -> void:
	# A planet can change (colonised, captured): check its look twice a second.
	_look_timer -= delta
	if _look_timer > 0.0:
		return
	_look_timer = 0.5
	if _look_key != _key():
		_apply_look()


func _key() -> String:
	return "%s|%s|%s" % [String(body.get("kind", "")), str(body.get("colour", "")), str(body.get("capacity", 1))]


func _apply_look() -> void:
	_look_key = _key()
	var mat := _mat
	var look := _look()
	mat.set_shader_parameter("mode", int(look["mode"]))
	for key in ["c_deep", "c_sea", "c_land1", "c_land2", "c_land3", "c_cloud", "c_atmo"]:
		mat.set_shader_parameter(key, look[key] as Color)
	mat.set_shader_parameter("land_level", float(look["level"]))
	if int(look["mode"]) == EARTH:
		mat.set_shader_parameter("earth_map", _earth_map())
	mat.set_shader_parameter("cloud_cover", float(look["clouds"]))


## The palette for this body: [mode, sea, land, clouds, atmosphere].
func _look() -> Dictionary:
	if giant:
		var blue := Color(body.get("colour", Color("9c8a5e"))).b > Color(body.get("colour", Color("9c8a5e"))).r
		if blue:
			return _pal(GAS, "000000", "000000", "a8c0d8", "6a86a8", "e0ecf8", "ffffff", Color("a0c8ff", 0.35), 0.0, 0.0)
		return _pal(GAS, "000000", "000000", "c8b07a", "8a7448", "eadcb4", "ffffff", Color("d8c08a", 0.35), 0.0, 0.0)
	var kind := String(body.get("kind", "random"))
	if kind == "molten":
		# Dark crust with glowing lava pools and a hot orange haze.
		return _pal(ROCKY, "000000", "000000", "4a2e26", "2e1e1a", "ff7a2a", "ffffff", Color("ff8a3a", 0.35), 0.0, 0.0)
	if int(body.get("capacity", 1)) <= 0:
		return _pal(ROCKY, "000000", "000000", "8a8a8a", "6a6a6e", "3e3e44", "ffffff", Color(0, 0, 0, 0), 0.0, 0.0)
	match kind:
		"earth":
			return _pal(EARTH, "1b3a6e", "2f6fb8", "c9b27a", "4f8a3a", "2f5a2a", "f2f6fa", Color("6fb4ff", 0.6), 0.0, 0.28)
		"continental":
			return _pal(TERRAN, "23406a", "3a7bbf", "d4c08a", "5fa046", "3a6e30", "f2f6fa", Color("8fd0ff", 0.55), 0.45, 0.35)
		"mars":
			return _pal(DESERT, "5a2416", "7a3a24", "c87a4e", "a0522e", "6e301c", "f0cdb4", Color("e8a07a", 0.35), 0.0, 0.1)
	var hex := Color(body.get("colour", Color("6f9a5a"))).to_html(false)
	match hex:
		"6f9a5a":
			return _pal(TERRAN, "22406a", "3a78b4", "cdb886", "6aa050", "3e6e34", "f0f4f8", Color("8fd0ff", 0.5), 0.5, 0.4)
		"5f8fa8":
			return _pal(TERRAN, "1a3560", "2e6aa8", "c0d8c8", "7ab090", "4e8068", "f4f8fc", Color("7ac0ff", 0.55), 0.68, 0.5)
		"c27a4a":
			return _pal(DESERT, "5a2a18", "7a3c24", "d08a5a", "b0603a", "7a3a24", "f2d6c0", Color("e8a07a", 0.35), 0.0, 0.12)
		"b8a27a":
			return _pal(DESERT, "6a5636", "8c7046", "e0cc96", "c2a46a", "8c7046", "f8f0dc", Color("e8d8a0", 0.35), 0.0, 0.15)
		"8a7fb0":
			return _pal(ICE, "4a3f7a", "7a6fb0", "b8b0e0", "9a8fd0", "6a5fa0", "ece8ff", Color("b0a0ff", 0.5), 0.5, 0.3)
	# Anything else: tint a terran world with its own colour.
	var c := Color(body.get("colour", Color("6f9a5a")))
	return {"mode": TERRAN, "c_deep": Color("1f3d6b"), "c_sea": Color("2f6fb0"), "c_land1": c.lightened(0.3), "c_land2": c, "c_land3": c.darkened(0.35),
		"c_cloud": Color("f0f4f8"), "c_atmo": Color(c.lightened(0.4), 0.45), "level": 0.5, "clouds": 0.35}


## Earth's world map as a texture (built once from EARTH_MAP).
static func _earth_map() -> ImageTexture:
	if _earth_texture == null:
		var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
		for y: int in EARTH_MAP.size():
			var row: String = EARTH_MAP[y]
			for x: int in row.length():
				img.set_pixel(x, y, EARTH_COLOURS.get(row[x], Color(0, 0, 0, 0)))
		_earth_texture = ImageTexture.create_from_image(img)
	return _earth_texture


func _pal(mode: int, deep: String, sea: String, l1: String, l2: String, l3: String, cloud: String, atmo: Color, level: float, clouds: float) -> Dictionary:
	return {"mode": mode, "c_deep": Color(deep), "c_sea": Color(sea), "c_land1": Color(l1), "c_land2": Color(l2), "c_land3": Color(l3),
		"c_cloud": Color(cloud), "c_atmo": atmo, "level": level, "clouds": clouds}
