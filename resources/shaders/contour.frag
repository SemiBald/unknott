#version 330

// NOTE: Render size values must be passed from code
uniform vec2 iResolution;
uniform float iTime;
uniform float Offset;
const float PI = 3.14159, K1 = 0.366025404, K2 = 0.211324865;

vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43.7585) * 2. - 1.;
}

float fbm4(vec2 p) {
    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    float m = step(a.y, a.x);
    vec2 o = vec2(m, 1. - m);
    vec2 b = a - o + K2;
    vec2 c = a - 1. + 2. * K2;
    vec3 h = max(.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.);
    vec3 n = h * h * h * h * vec3(dot(a, hash(i + 0.)), dot(b, hash(i + o)), dot(c, hash(i + 1.)));
    return dot(n, vec3(70.));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 p = 2. * uv - Offset;
    p.x *= iResolution.x / iResolution.y;
    vec3 col = vec3(0.), acc = vec3(0.);
    float lh = -iResolution.y, off = .1 * iTime, h = 0., z = .1, zi = .05;
    const int l = 12;
    for (int i = 0; i < l; ++i) {
        vec2 pOffset = vec2(p.x, z + off);
        float n = .4 * fbm4(pOffset);
        h = n - p.y;
        if (h > lh) {
            float d = abs(h);
            col = vec3(smoothstep(1., 0., d * 192.));
            col *= exp(-.1 * float(i));
            lh = h;
        }
        acc += col;
        z += zi;
    }
    col = sqrt(clamp(acc, 0., 2.));
    vec3 b = col * col * col;
    
    fragColor = vec4(b* vec3(0.0353, 0.2078, 0.6902), b * 0.1);
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    vec4 fragColor;

    mainImage(fragColor, fragCoord);

    gl_FragColor = fragColor;
}
