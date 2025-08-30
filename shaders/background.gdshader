shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_tex : hint_screen_texture;
uniform float intensity : hint_range(0.0, 1.0) = 1.6;   // overall effect
uniform float wobble_amp : hint_range(0.0, 8.0) = 2.0;  // px distortion
uniform float wobble_freq : hint_range(0.1, 10.0) = 9.0;
uniform float wobble_speed : hint_range(0.0, 5.0) = 0.0;

uniform float tint_strength : hint_range(0.0, 1.0) = 0.30;
uniform vec3  tint_color = vec3(0.05, 0.35, 0.55);      // sea blue

uniform float fog_strength : hint_range(0.0, 1.0) = 0.35;  // top-bright to deep-dark
uniform float fog_curve    : hint_range(0.2, 4.0) = 1.3;

uniform float rays_strength : hint_range(0.0, 1.0) = 0.15;
uniform float rays_speed    : hint_range(0.0, 3.0) = 0.0;
uniform float rays_angle    : hint_range(-3.14, 3.14) = -0.0;

uniform float caustics_strength : hint_range(0.0, 1.0) = 0.18;
uniform float caustics_scale    : hint_range(2.0, 20.0) = 8.0;
uniform float caustics_speed    : hint_range(0.0, 3.0) = 0.0;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.25;

float hash(vec2 p){ return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453); }

void fragment() {
    vec2 uv = SCREEN_UV;

    // --- gentle wobble (two-phase sine for organic motion)
    float t = TIME * wobble_speed;
    vec2 wob = vec2(
        sin(uv.y * wobble_freq * 6.283 + t) * 0.5 +
        sin((uv.y*1.7 + 1.3) * wobble_freq * 6.283 - t*0.8) * 0.5,
        sin(uv.x * wobble_freq * 6.283 - t*1.2) * 0.5 +
        sin((uv.x*1.9 - 0.6) * wobble_freq * 6.283 + t) * 0.5
    );
    vec2 suv = uv + wobble_amp * wob * SCREEN_PIXEL_SIZE; // pixel-scale safe

    // --- base scene sample
    vec3 col = texture(screen_tex, clamp(suv, vec2(0.0), vec2(1.0))).rgb;

    // --- light rays (angled moving bands)
    vec2 dir = vec2(cos(rays_angle), sin(rays_angle));
    float bands = 0.5 + 0.5 * sin(dot(uv, dir) * 55.0 + t * 3.1415 * rays_speed);
    float rays = smoothstep(0.55, 1.0, bands) * (1.0 - uv.y); // stronger near top
    col += rays_strength * rays * vec3(1.0, 1.0, 0.95);

    // --- procedural caustics (sum of warped sines)
    vec2 cuv = uv * caustics_scale + vec2(t*0.25, -t*0.18);
    float c1 = sin(cuv.x*6.283) * sin((cuv.y+0.31)*6.283);
    float c2 = sin((cuv.x*1.7+0.7)*6.283) * sin((cuv.y*1.3-0.2)*6.283);
    float c = pow(max(0.0, c1 + c2), 2.0);
    col += caustics_strength * c * (1.0 - uv.y) * vec3(0.9, 0.95, 1.0);

    // --- depth fog from top (surface) to bottom
    float depth = pow(uv.y, fog_curve);
    col = mix(col, col * (1.0 - fog_strength) + vec3(0.02,0.05,0.08)*fog_strength, depth);

    // --- color tint
    col = mix(col, col * (1.0 - tint_strength) + tint_color * tint_strength, intensity);

    // --- vignette
    vec2 d = uv - 0.5;
    float vign = smoothstep(0.9, 0.3, dot(d,d));
    col *= mix(1.0, 1.0 - vignette_strength, 1.0 - vign);

    COLOR = vec4(col, 1.0);
}