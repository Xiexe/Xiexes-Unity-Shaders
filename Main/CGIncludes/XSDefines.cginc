#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
#include "UnityCG.cginc"

struct VertexInput
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 color : COLOR;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput
{
    #if defined(Geometry)
        float4 pos : CLIP_POS;
        float4 vertex : SV_POSITION; // We need both of these in order to shadow Outlines correctly
    #else
        float4 pos : SV_POSITION;
    #endif

    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float3 ntb[3] : TEXCOORD2; //texcoord 3, 4 || Holds World Normal, Tangent, and Bitangent
    float4 worldPos : TEXCOORD5;
    float4 color : TEXCOORD6;
    float3 normal : TEXCOORD8;
    float4 screenPos : TEXCOORD9;
    float3 objPos : TEXCOORD11;
    float2 uv2 : TEXCOORD12;

    #if !defined(UNITY_PASS_SHADOWCASTER)
        SHADOW_COORDS(7)
        UNITY_FOG_COORDS(10)
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

#if defined(Geometry)
    struct v2g
    {
        float4 pos : CLIP_POS;
        float4 vertex : SV_POSITION;
        float2 uv : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float3 ntb[3] : TEXCOORD2; //texcoord 3, 4 || Holds World Normal, Tangent, and Bitangent
        float4 worldPos : TEXCOORD5;
        float4 color : TEXCOORD6;
        float3 normal : TEXCOORD8;
        float4 screenPos : TEXCOORD9;
        float3 objPos : TEXCOORD11;
        float2 uv2 : TEXCOORD12;

        #if !defined(UNITY_PASS_SHADOWCASTER)
            SHADOW_COORDS(7)
            UNITY_FOG_COORDS(10)
        #endif

        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct g2f
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float3 ntb[3] : TEXCOORD2; //texcoord 3, 4 || Holds World Normal, Tangent, and Bitangent
        float4 worldPos : TEXCOORD5;
        float4 color : TEXCOORD6;
        float4 screenPos : TEXCOORD8;
        float3 objPos : TEXCOORD10;

        #if !defined(UNITY_PASS_SHADOWCASTER)
            SHADOW_COORDS(7)
            UNITY_FOG_COORDS(9)
        #endif

        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };
#endif

struct XSLighting
{
    half4 albedo;
    half4 normalMap;
    half4 detailNormal;
    half4 detailMask;
    half4 metallicGlossMap;
    half4 reflectivityMask;
    half4 specularMap;
    half4 thickness;
    half4 occlusion;
    half4 emissionMap;
    half4 rampMask;
    half4 hsvMask;
    half4 clipMap;
    half4 dissolveMask;
    half3 diffuseColor;
    half attenuation;
    half3 normal;
    half3 tangent;
    half3 bitangent;
    half4 worldPos;
    half3 color;
    half alpha;
    float isOutline;
    float4 screenPos;
    float2 screenUV;
    float3 objPos;
};

struct TextureUV
{
    half2 uv0;
    half2 uv1;
    half2 albedoUV;
    half2 specularMapUV;
    half2 metallicGlossMapUV;
    half2 detailMaskUV;
    half2 normalMapUV;
    half2 detailNormalUV;
    half2 thicknessMapUV;
    half2 occlusionUV;
    half2 reflectivityMaskUV;
    half2 emissionMapUV;
    half2 outlineMaskUV;
    half2 clipMapUV;
    half2 dissolveUV;
};

struct DotProducts
{
    half ndl;
    half vdn;
    half vdh;
    half tdh;
    half bdh;
    half ndh;
    half rdv;
    half ldh;
    half svdn;
};

struct VertexLightInformation {
    float3 Direction[4];
    float3 ColorFalloff[4];
    float Attenuation[4];
};

UNITY_DECLARE_TEX2D(_MainTex); half4 _MainTex_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_ClipMap); half4 _ClipMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_DissolveTexture); half4 _DissolveTexture_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap); half4 _BumpMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailNormalMap); half4 _DetailNormalMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailMask); half4 _DetailMask_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_SpecularMap); half4 _SpecularMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_MetallicGlossMap); half4 _MetallicGlossMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_ReflectivityMask); half4 _ReflectivityMask_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_ThicknessMap); half4 _ThicknessMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap); half4 _EmissionMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_RampSelectionMask);
UNITY_DECLARE_TEX2D_NOSAMPLER(_HSVMask);
sampler2D _OcclusionMap; half4 _OcclusionMap_ST;
sampler2D _OutlineMask;
sampler2D _Matcap;
sampler2D _Ramp;
samplerCUBE _BakedCubemap;
sampler2D _GrabTexture;
float4 _GrabTexture_TexelSize;

#if defined(UNITY_PASS_SHADOWCASTER)
    sampler3D _DitherMaskLOD;
#endif

half4 _Color;
half4 _ClipAgainstVertexColorGreaterZeroFive, _ClipAgainstVertexColorLessZeroFive;
half _Cutoff;
half _DissolveProgress, _DissolveStrength;
int _DissolveCoordinates;
int _UseClipsForDissolve;

half4 _ShadowRim,
      _OutlineColor, _SSColor,
      _EmissionColor, _MatcapTint,
      _RimColor, _DissolveColor;

half _MatcapTintToDiffuse;

half _FadeDitherDistance;
half _EmissionToDiffuse, _ScaleWithLightSensitivity;
half _Hue, _Saturation, _Value;
half _Metallic, _Glossiness, _OcclusionIntensity, _Reflectivity, _ClearcoatStrength, _ClearcoatSmoothness;
half _BumpScale, _DetailNormalMapScale;
half _SpecularIntensity, _SpecularSharpness, _SpecularArea, _AnisotropicSpecular, _AnisotropicReflection, _SpecularAlbedoTint;
half _IOR;
half _HalftoneDotSize, _HalftoneDotAmount, _HalftoneLineAmount, _HalftoneLineIntensity;
half _RimRange, _RimThreshold, _RimIntensity, _RimSharpness, _RimAlbedoTint, _RimCubemapTint, _RimAttenEffect;
half _ShadowRimRange, _ShadowRimThreshold, _ShadowRimSharpness, _ShadowSharpness, _ShadowRimAlbedoTint;
half _SSDistortion, _SSPower, _SSScale;
half _OutlineWidth;

int _HalftoneType;
int _FadeDither;
int _BlendMode;
int _OcclusionMode;
int _UseRefraction;
int _ReflectionMode, _ReflectionBlendMode, _ClearCoat;
int _TilingMode, _VertexColorAlbedo, _ScaleWithLight;
int _OutlineAlbedoTint, _OutlineLighting, _OutlineNormalMode;
int _UVSetAlbedo, _UVSetNormal, _UVSetDetNormal,
    _UVSetDetMask, _UVSetMetallic, _UVSetSpecular,
    _UVSetThickness, _UVSetOcclusion, _UVSetReflectivity,
    _UVSetEmission, _UVSetClipMap, _UVSetDissolve;
int _NormalMapMode, _OutlineUVSelect;

//Defines for helper functions
#define grayscaleVec float3(0.2125, 0.7154, 0.0721)
#define WorldNormalVector(normal0, normal) half3(dot(normal0,normal), dot(normal0, normal), dot(normal0,normal))