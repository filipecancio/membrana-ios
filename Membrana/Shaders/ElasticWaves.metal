#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Signed Distance Functions (SDF)

/// Signed Distance Function para uma caixa com cantos arredondados (Pílula Central)
/// - Parameters:
///   - p: Coordenada local relativa ao centro da caixa (position - uBoxCenter)
///   - b: Meia-largura e meia-altura (width / 2, height / 2)
///   - r: Raio de arredondamento dos cantos
static inline float sdRoundBox(float2 p, float2 b, float r) {
    float2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0f) + length(max(q, 0.0f)) - r;
}

/// Signed Distance Function para uma esfera/círculo 2D (Bola Invasora)
static inline float sdCircle(float2 p, float r) {
    return length(p) - r;
}

/// Polynomial Smooth Minimum Quadrático (Inigo Quilez)
/// Retorna float2(distância_combinada, fator_interpolação_blend)
static inline float2 smin(float a, float b, float k) {
    float safeK = max(k, 0.001f);
    float h = max(safeK - abs(a - b), 0.0f) / safeK;
    float m = h * h * 0.5f;
    float s = m * safeK * 0.5f;
    if (a < b) {
        return float2(a - s, m);
    } else {
        return float2(b - s, 1.0f - m);
    }
}

/// Avalia o campo escalar combinado (SDF da membrana fundida) em qualquer ponto p
static inline float2 evaluateMembraneField(
    float2 p,
    float2 boxCenter,
    float2 boxHalfSize,
    float boxRadius,
    float2 ballCenter,
    float ballRadius,
    float blendK
) {
    float dBox = sdRoundBox(p - boxCenter, boxHalfSize, boxRadius);
    float dBall = sdCircle(p - ballCenter, ballRadius);
    return smin(dBox, dBall, blendK);
}

// MARK: - Stitchable SwiftUI Layer Shader (Liquid Glass + SDF Membrane)

/// Shader principal do Membrana para SwiftUI (.layerEffect).
/// Combina Signed Distance Fields + Smooth Minimum com a óptica Liquid Glass do iOS:
/// - Refração da camada de fundo (SwiftUI::Layer) guiada pelo gradiente normal (∇d) do SDF
/// - Dispersão cromática sutil nas bordas curvas do menisco líquido
/// - Iluminação especular (Blinn-Phong) e borda Fresnel cristalina
[[ stitchable ]] half4 liquidGlassMembrane(
    float2 position,
    SwiftUI::Layer layer,
    float2 uBoxCenter,
    float2 uBoxSize,
    float uBoxRadius,
    float2 uBallCenter,
    float uBallRadius,
    float uBlendK,
    float uGlassRefraction,
    half4 uBoxColor,
    half4 uBallColor
) {
    // 1. Avaliação do SDF combinado e fator de mistura (0.0 = Box, 1.0 = Ball)
    float2 combined = evaluateMembraneField(
        position,
        uBoxCenter,
        uBoxSize,
        uBoxRadius,
        uBallCenter,
        uBallRadius,
        uBlendK
    );
    float dist = combined.x;
    float blend = combined.y;

    // 2. Anti-aliasing analítico sub-pixel na borda externa (faixa de 1pt centrada em dist = 0)
    float aa = clamp(0.5f - dist, 0.0f, 1.0f);

    // Fora da membrana: preserva intacto o pixel original do fundo da tela
    if (aa <= 0.0f) {
        return layer.sample(position);
    }

    // 3. Cálculo do Gradiente 2D (∇d) via diferenças finitas para obter a normal da superfície
    const float eps = 1.0f;
    float dx = evaluateMembraneField(position + float2(eps, 0.0f), uBoxCenter, uBoxSize, uBoxRadius, uBallCenter, uBallRadius, uBlendK).x
             - evaluateMembraneField(position - float2(eps, 0.0f), uBoxCenter, uBoxSize, uBoxRadius, uBallCenter, uBallRadius, uBlendK).x;
    float dy = evaluateMembraneField(position + float2(0.0f, eps), uBoxCenter, uBoxSize, uBoxRadius, uBallCenter, uBallRadius, uBlendK).x
             - evaluateMembraneField(position - float2(0.0f, eps), uBoxCenter, uBoxSize, uBoxRadius, uBallCenter, uBallRadius, uBlendK).x;
    float2 grad2D = normalize(float2(dx, dy) + 1e-5f);

    // 4. Perfil de cúpula líquida 3D a partir da profundidade interna (-dist)
    // Perto da borda (dist -> 0), a curvatura é máxima; no interior profundo, a lente achata suavemente.
    float bevelThickness = 26.0f;
    float edgeFactor = 1.0f - clamp(-dist / bevelThickness, 0.0f, 1.0f);
    float edgeCurve = edgeFactor * edgeFactor; // Curvatura quadrática suave na borda

    float nz = sqrt(max(1.0f - edgeCurve * 0.85f, 0.05f));
    float3 normal3D = normalize(float3(grad2D * edgeCurve, nz));

    // 5. Refração Óptica do Fundo (Liquid Glass Lensing + Dispersão Cromática)
    float refractionAmplitude = 28.0f * uGlassRefraction * edgeCurve;
    float2 refractOffset = -grad2D * refractionAmplitude;

    // Aberração cromática sutil nas bordas de alta tensão
    float dispersion = 0.14f * uGlassRefraction * edgeCurve;
    half4 bgSampleR = layer.sample(position + refractOffset * (1.0f + dispersion));
    half4 bgSampleG = layer.sample(position + refractOffset);
    half4 bgSampleB = layer.sample(position + refractOffset * (1.0f - dispersion));
    half3 refractedBg = half3(bgSampleR.r, bgSampleG.g, bgSampleB.b);

    // 6. Cor base da membrana interpolada entre Box (Branco Cristal) e Bola (Coral/Vermelho)
    half4 baseTint = mix(uBoxColor, uBallColor, half(blend));

    // 7. Iluminação Especular Liquid Glass (Luz direcional superior-esquerda + Rim Fresnel)
    float3 lightDir = normalize(float3(-0.45f, -0.65f, 0.60f));
    float3 viewDir  = float3(0.0f, 0.0f, 1.0f);
    float3 halfVec  = normalize(lightDir + viewDir);

    float specAngle = max(dot(normal3D, halfVec), 0.0f);
    float specular  = pow(specAngle, 36.0f) * 0.85f;

    // Efeito Fresnel: borda interna translúcida e brilhante característica do Liquid Glass
    float fresnel = pow(edgeFactor, 2.2f);
    float innerRim = smoothstep(0.0f, 1.0f, clamp(1.0f - abs(dist + 1.5f) / 2.2f, 0.0f, 1.0f));

    // 8. Composição entre o modo Liquid Glass e a pigmentação da membrana
    half glassMix = half(clamp(uGlassRefraction * 0.68f, 0.0f, 0.85f));
    half3 tintedGlass = mix(baseTint.rgb, refractedBg * mix(half3(1.0h), baseTint.rgb, 0.55h), glassMix);

    // Adiciona brilho Fresnel perolado e reflexo especular direto
    half3 rimHighlight = mix(half3(1.0h, 1.0h, 1.0h), baseTint.rgb, 0.25h) * half(fresnel * 0.55f + innerRim * 0.45f);
    half3 finalRGB = clamp(tintedGlass + rimHighlight + half3(specular), 0.0h, 1.0h);

    // 9. Combinação anti-aliased com o fundo fora da borda
    half4 bgOriginal = layer.sample(position);
    return mix(bgOriginal, half4(finalRGB, 1.0h), half(aa));
}
