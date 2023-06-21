#version 330

// NOTE: Render size values must be passed from code
uniform vec2 iResolution;
uniform float vignetteIntensity;
uniform float blackness;

float random(vec2 st)
{
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec3 perceptualDither(vec2 fragCoord, vec3 color)
{
    vec2 noiseScale = vec2(1.0) / iResolution.xy;
    vec2 pixelCoord = fragCoord + 0.5; // Center of the pixel

    float noiseR = random(pixelCoord * noiseScale);
    float noiseG = random((pixelCoord + vec2(1.0, 0.0)) * noiseScale);
    float noiseB = random((pixelCoord + vec2(0.0, 1.0)) * noiseScale);

    // Adjust the dithering strength based on color perception
    float ditherStrength = 0.25; // Adjust this value to control the dithering strength

    // Calculate the final dithered color
    vec3 ditheredColor = color + vec3(noiseR - 0.7, noiseG - 0.7, noiseB - 0.7) * ditherStrength;

    return ditheredColor;
}

vec3 applyGaussianBlur(vec2 fragCoord, float blurRadius, vec3 color)
{
    vec2 texelSize = 1.0 / iResolution.xy;
    vec3 blurColor = vec3(0.0);

    // Gaussian kernel
    float kernel[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    
    for (int i = -2; i <= 2; i++)
    {
        float offsetX = float(i) * texelSize.x;
        
        for (int j = -2; j <= 2; j++)
        {
            float offsetY = float(j) * texelSize.y;
            blurColor += color * kernel[i + 2] * kernel[j + 2];
        }
    }
    
    return blurColor;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float vignetteIntensitySquared = vignetteIntensity * vignetteIntensity;

    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 centeredUV = (uv - 0.5) * 2.0;

    float distanceSquared = dot(centeredUV, centeredUV) * 1.3;
    float vignetteFactor = 1.0 - distanceSquared * vignetteIntensitySquared;

    // Apply dithering
    vec3 ditheredColor = perceptualDither(fragCoord, fragColor.rgb);
    // Floyd-Steinberg dithering
    float diffusionStrength = 0.2; // Adjust this value to control the diffusion strength

    vec3 quantError = fragColor.rgb - ditheredColor * fragColor.rgb;
    fragColor.rgb = ditheredColor;

    if (fragCoord.x < iResolution.x - 1.0 && fragCoord.y < iResolution.y - 1.0)
    {
        vec3 newPixel = vec3(0.0);

        // Apply the Floyd-Steinberg diffusion matrix
        newPixel += quantError * diffusionStrength * 0.4375;
        fragColor.rgb += newPixel;

        newPixel = vec3(0.0);
        newPixel += quantError * diffusionStrength * 0.1875;
        fragColor.rgb += newPixel;

        newPixel = vec3(0.0);
        newPixel += quantError * diffusionStrength * 0.3125;
        fragColor.rgb += newPixel;

        newPixel = vec3(0.0);
        newPixel += quantError * diffusionStrength * 0.0625;
        fragColor.rgb += newPixel;
    }

    // Apply Gaussian blur
    float blurRadius = 100000000.141; // Adjust this value to control the blur radius
    fragColor.rgb = applyGaussianBlur(fragCoord, blurRadius, fragColor.rgb);

    //use * vec3(0.0353, 0.2078, 0.6902)/2
    fragColor = vec4((blackness - vignetteFactor + ((fragColor.rgb) * vignetteFactor)) * vec3(0.0353, 0.2078, 0.6902), 1.0 - vignetteFactor);
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    vec4 fragColor;

    mainImage(fragColor, fragCoord);

    gl_FragColor = fragColor;
}
