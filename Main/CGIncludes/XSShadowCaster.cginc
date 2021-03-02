#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"

// Do dithering for alpha blended shadows on SM3+/desktop, and Dithered transparency;
// on lesser systems do simple alpha-tested shadows
#if defined(_ALPHABLEND_ON) || defined(_ALPHATEST_ON)
    #if !((SHADER_TARGET < 30) || defined (SHADER_API_MOBILE) || defined(SHADER_API_D3D11_9X) || defined (SHADER_API_PSP2) || defined (SHADER_API_PSM))
        #define UNITY_STANDARD_USE_DITHER_MASK 1
    #endif
#endif

// Need to output UVs in shadow caster, since we need to sample texture and do clip/dithering based on it
#if defined(_ALPHABLEND_ON) || defined(_ALPHATEST_ON)
    #define UNITY_STANDARD_USE_SHADOW_UVS 1
#endif

uniform float4      _ClipAgainstVertexColorGreaterZeroFive, _ClipAgainstVertexColorLessZeroFive;
uniform float4      _Color;
uniform float       _Cutoff;
uniform sampler2D   _MainTex;
uniform sampler2D   _CutoutMask;
uniform sampler2D   _ClipMap;
uniform float4      _MainTex_ST;
uniform float       _FadeDither;
uniform float       _FadeDitherDistance;
uniform int         _BlendMode;
#ifdef UNITY_STANDARD_USE_DITHER_MASK
    uniform sampler3D   _DitherMaskLOD;
#endif

struct VertexInput
{
    float4 vertex   : POSITION;
    float3 normal   : NORMAL;
    float2 uv0      : TEXCOORD0;
    float4 color    : COLOR;
};


// Don't make the structure if it's empty (it's an error to have empty structs on some platforms...)
#if !defined(V2F_SHADOW_CASTER_NOPOS_IS_EMPTY) || defined(UNITY_STANDARD_USE_SHADOW_UVS)
struct VertexOutputShadowCaster
{
    V2F_SHADOW_CASTER_NOPOS
        // Need to output UVs in shadow caster, since we need to sample texture and do clip/dithering based on it
    #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
        float2 tex : TEXCOORD1;
    #endif

    float4 worldPos : TEXCOORD2;
    float4 screenPos : TEXCOORD3;
    float4 color : COLOR;
};
#endif

half2 calcScreenUVs(half4 screenPos)
{
    half2 uv = screenPos / (screenPos.w + 0.0000000001); //0.0x1 Stops division by 0 warning in console.
    #if UNITY_SINGLE_PASS_STEREO
        uv.xy *= half2(_ScreenParams.x * 2, _ScreenParams.y);
    #else
        uv.xy *= _ScreenParams.xy;
    #endif

    return uv;
}

inline half Dither8x8Bayer( int x, int y )
{
    const half dither[ 64 ] = {
    1, 49, 13, 61,  4, 52, 16, 64,
    33, 17, 45, 29, 36, 20, 48, 32,
    9, 57,  5, 53, 12, 60,  8, 56,
    41, 25, 37, 21, 44, 28, 40, 24,
    3, 51, 15, 63,  2, 50, 14, 62,
    35, 19, 47, 31, 34, 18, 46, 30,
    11, 59,  7, 55, 10, 58,  6, 54,
    43, 27, 39, 23, 42, 26, 38, 22};
    int r = y * 8 + x;
    return dither[r] / 64;
}

half calcDither(half2 screenPos)
{
    half dither = Dither8x8Bayer(fmod(screenPos.x, 8), fmod(screenPos.y, 8));
    return dither;
}

// We have to do these dances of outputting SV_POSITION separately from the vertex shader,
// and inputting VPOS in the pixel shader, since they both map to "POSITION" semantic on
// some platforms, and then things don't go well.


void vertShadowCaster(VertexInput v,
    #if !defined(V2F_SHADOW_CASTER_NOPOS_IS_EMPTY) || defined(UNITY_STANDARD_USE_SHADOW_UVS)
        out VertexOutputShadowCaster o,
    #endif
    out float4 opos : SV_POSITION)
{
    TRANSFER_SHADOW_CASTER_NOPOS(o, opos)
    #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
        o.tex = TRANSFORM_TEX(v.uv0, _MainTex);
        o.color = v.color;
        o.worldPos = mul(unity_ObjectToWorld, v.vertex);
        o.screenPos = ComputeScreenPos(opos);
    #endif
}

float AlphaAdjust(float alphaToAdj, float3 vColor)
{
    _ClipAgainstVertexColorGreaterZeroFive = saturate(_ClipAgainstVertexColorGreaterZeroFive); //So the lerp doesn't go crazy
    _ClipAgainstVertexColorLessZeroFive = saturate(_ClipAgainstVertexColorLessZeroFive);

    float modR = vColor.r < 0.5 ? _ClipAgainstVertexColorLessZeroFive.r : _ClipAgainstVertexColorGreaterZeroFive.r;
    float modG = vColor.g < 0.5 ? _ClipAgainstVertexColorLessZeroFive.g : _ClipAgainstVertexColorGreaterZeroFive.g;
    float modB = vColor.b < 0.5 ? _ClipAgainstVertexColorLessZeroFive.b : _ClipAgainstVertexColorGreaterZeroFive.b;

    alphaToAdj *= lerp(0, 1, lerp(1, modR, step(0.01, vColor.r)));
    alphaToAdj *= lerp(0, 1, lerp(1, modG, step(0.01, vColor.g)));
    alphaToAdj *= lerp(0, 1, lerp(1, modB, step(0.01, vColor.b)));

    return alphaToAdj;
}

half4 fragShadowCaster(
    #if !defined(V2F_SHADOW_CASTER_NOPOS_IS_EMPTY) || defined(UNITY_STANDARD_USE_SHADOW_UVS)
        VertexOutputShadowCaster i
    #endif
    #ifdef UNITY_STANDARD_USE_DITHER_MASK
        , UNITY_VPOS_TYPE vpos : VPOS
    #endif
) : SV_Target
{
    #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
        half alpha = 1;
        float4 albedo = tex2D(_MainTex, i.tex).a * _Color.a;
        float4 clipMap = tex2D(_ClipMap, i.tex);
        float modifiedAlpha = AlphaAdjust(albedo.a, clipMap.rgb);

        #if defined(_ALPHABLEND_ON) || defined(_ALPHATEST_ON)
            float2 screenUV = calcScreenUVs(i.screenPos);
            if(_BlendMode >= 3)
            {
                half dither = calcDither(screenUV);
                alpha = modifiedAlpha - (dither * (1-albedo.a) * 0.15);
            }

            if(_BlendMode == 2)
            {
                half dither = calcDither(screenUV);

                float fadeDist = abs(_FadeDitherDistance);
                float d = distance(_WorldSpaceCameraPos, i.worldPos);
                d = smoothstep(fadeDist, fadeDist + 0.05, d);
                d = lerp(d, 1-d, saturate(step(0, _FadeDitherDistance)));
                dither += lerp(0, d, saturate(_FadeDither));
                clip(modifiedAlpha - dither);
            }

            if(_BlendMode == 1)
            {
                clip(modifiedAlpha - _Cutoff);
            }
        #else
            alpha = modifiedAlpha;
        #endif
    #endif

    SHADOW_CASTER_FRAGMENT(i)
}