// ═══════════════════════════════════════════════════════════════════════
// VOID TERMINAL — Screen Post-Processing Shader
// Load via: decoration { screen_shader = ~/.config/hypr/shaders/void-grain.frag }
//
// Effects:
//   · Film grain      — static analog-noise pattern (position-based hash)
//   · Scanlines       — 1 px dark stripe every 3 px for CRT feel
//   · Vignette        — corners darkened toward void black
//   · Color grade     — subtle cool/teal shift, warm tones suppressed
// ═══════════════════════════════════════════════════════════════════════

#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;

out vec4 fragColor;

// ── Tunable constants ────────────────────────────────────────────────
const float GRAIN_GRID_SIZE    = 1400.0;  // virtual pixels per UV unit; finer → smaller grain
const float GRAIN_STRENGTH     = 0.065;   // ±amplitude of the grain offset  (0 = off)
const float SCANLINE_DENSITY   = 450.0;   // number of scanline pairs across screen height
const float SCANLINE_BASE      = 0.965;   // brightness of lit scanline   (1.0 = no effect)
const float SCANLINE_INTENSITY = 0.035;   // additional brightness on the bright line
const float VIGNETTE_START     = 0.45;    // inner radius of vignette smooth-step
const float VIGNETTE_END       = 1.55;    // outer radius of vignette smooth-step
const float VIGNETTE_FLOOR     = 0.70;    // minimum brightness at screen corners
const float GRADE_R            = 0.95;    // red channel multiplier   (< 1.0 = cooler)
const float GRADE_G            = 1.005;   // green channel multiplier (≈ 1.0 = neutral)
const float GRADE_B            = 1.06;    // blue channel multiplier  (> 1.0 = teal push)

// ── Hash / pseudo-noise ──────────────────────────────────────────────
// Returns [0,1]. Seeded by a 2-D integer coordinate so the grain is
// stable per pixel (analog film grain look, not animated TV snow).
float hash(vec2 p) {
    p = fract(p * vec2(0.1031, 0.1030));
    p += dot(p, p.yx + 33.33);
    return fract((p.x + p.y) * p.x);
}

void main() {
    vec2 uv = v_texcoord;
    vec4 color = texture(tex, uv);

    // ── 1. Film grain ──────────────────────────────────────────────
    // 1 400-pixel virtual grid gives a fine grain that reads as texture
    // rather than blocky noise at any typical display resolution.
    float grain = (hash(floor(uv * GRAIN_GRID_SIZE)) - 0.5) * GRAIN_STRENGTH;
    color.rgb += grain;

    // ── 2. Scanlines ───────────────────────────────────────────────
    // One slightly darker line every 3 virtual pixels.
    // fract(uv.y * 450) gives ~450 stripes across the screen height;
    // step(0.67, ...) makes the bottom third of each stripe darker.
    float scanline = SCANLINE_BASE + SCANLINE_INTENSITY * step(0.5, fract(uv.y * SCANLINE_DENSITY));
    color.rgb *= scanline;

    // ── 3. Vignette ────────────────────────────────────────────────
    // Map UVs to [-1, 1], compute radial distance, smooth-fade toward
    // edges. max(..., 0.70) keeps centre untouched while corners reach
    // ~70 % brightness — just enough to feel like a CRT tube.
    vec2 c = uv * 2.0 - 1.0;
    float vignette = 1.0 - smoothstep(VIGNETTE_START, VIGNETTE_END, dot(c, c));
    color.rgb *= max(vignette, VIGNETTE_FLOOR);

    // ── 4. Void color grade ────────────────────────────────────────
    // Barely perceptible: pull red down ‑5 %, push blue up +6 %.
    // This gives warm-toned content a cool teal cast matching the UI
    // palette while keeping whites and teals untouched.
    color.r *= GRADE_R;
    color.g *= GRADE_G;
    color.b *= GRADE_B;

    fragColor = clamp(color, 0.0, 1.0);
}
