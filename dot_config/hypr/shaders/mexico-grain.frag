// ═══════════════════════════════════════════════════════════════════════
// MEKSiKA ATEŞi — Breaking Bad / Better Call Saul Style Shader
// Yüklemek için: decoration { screen_shader = ~/.config/hypr/shaders/mexico-grain.frag }
//
// Özellikler:
//   · Sıcak Renk Filtresi: Ekranı yoğun sarı/turuncu tona sokar.
//   · Doğal Film Greni: Void terminaldeki gibi statik değil, zamanla hareket eder.
//   · Kontrast & Pus: Daha az parlak beyazlar, daha derin gölgeler.
// ═══════════════════════════════════════════════════════════════════════

#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
uniform float time; // Hyprland bu değişkeni sağlar, grenin hareket etmesi için lazım.

out vec4 fragColor;

// ── Ayarlanabilir Ayarlar (Tunable Constants) ─────────────────────────
const float GRAIN_STRENGTH = 0.08;   // Grenin belirginliği (0.0 - 0.2 arası iyi)
const float GRAIN_SIZE = 1.8;       // Gren taneciklerinin boyutu
const float HEAT_HAZE = 0.15;        // Renk sıcaklığının yoğunluğu (Meksika etkisi)
const float EXPOSURE = 0.95;         // Ekranın genel parlaklığı (Biraz loşluk için)

// ── Hareketli Pseudo-Noise (Zamana Bağlı) ─────────────────────────────
float noise(vec2 p, float t) {
    vec2 s = vec2(640.0, 480.0);
    p = mod(p, s);
    return fract(sin(dot(p + t, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = v_texcoord;
    vec4 color = texture(tex, uv);

    // ── 1. Temel Renk ve Pozlama ─────────────────────────────────────
    // Ekranı hafifçe loşlaştırarak çöl havası veriyoruz.
    color.rgb *= EXPOSURE;

    // ── 2. Breaking Bad Meksika Filtresi ─────────────────────────────
    // Kırmızı ve Yeşili artırıp, Maviyi ciddi oranda kısıyoruz.
    // Bu, o meşhur "kirli sarı" tonunu verir.
    float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114)); // Parlaklık değeri
    
    // Sıcaklık efekti: Beyazlar sarıya kayar, siyahlar daha az etkilenir.
    vec3 hot_tint = vec3(1.2, 1.0, 0.4); // Yoğun Sarı/Turuncu mix
    color.rgb = mix(color.rgb, color.rgb * hot_tint, HEAT_HAZE);
    
    // Alternatif olarak, eğer daha "kirli" bir sarı istersen:
    // color.r *= 1.15;
    // color.g *= 1.05;
    // color.b *= 0.6; // Mavi çok kısılırsa sararır.

    // ── 3. Hareketli Film Greni (Tatlı Gren) ──────────────────────────
    // Statik hash yerine, 'time' kullanan hareketli gren daha doğal durur.
    vec2 noise_uv = uv * 1000.0 / GRAIN_SIZE;
    float n = noise(noise_uv, time * 0.01); // Gren yavaşça değişir
    
    // Greni renge ekle (Hafifçe parlatıp karartır)
    float grain = (n - 0.5) * GRAIN_STRENGTH;
    color.rgb += grain;

    // ── 4. Kontrast Ayarı (Sarıyı Ezmemek İçin) ───────────────────────
    // Gölgeleri biraz eziyoruz, parlak alanları yumuşatıyoruz.
    color.rgb = pow(color.rgb, vec3(1.1)); // Hafif gama artışı

    fragColor = clamp(color, 0.0, 1.0);
}