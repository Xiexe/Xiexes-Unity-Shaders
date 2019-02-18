#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
#include "UnityCG.cginc"

struct VertexInput
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;
	float4 color : COLOR;
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
	float2 uv1 : TEXCROORD1;
	float3 ntb[3] : TEXCOORD2; //texcoord 3, 4 || Holds World Normal, Tangent, and Bitangent
	float4 worldPos : TEXCOORD5;
	float4 color : TEXCOORD6;
	SHADOW_COORDS(7)
};


#if defined(Geometry)
	struct v2g
	{
		float4 pos : CLIP_POS;
		float4 vertex : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uv1 : TEXCROORD1;
		float3 ntb[3] : TEXCOORD2; //texcoord 3, 4 || Holds World Normal, Tangent, and Bitangent
		float4 worldPos : TEXCOORD5;
		float4 color : TEXCOORD6;
		SHADOW_COORDS(7)
	};

	struct g2f
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uv1 : TEXCROORD1;
		float3 ntb[3] : TEXCOORD2; //texcoord 3, 4 || Holds World Normal, Tangent, and Bitangent
		float4 worldPos : TEXCOORD5;
		float4 color : TEXCOORD6;
		SHADOW_COORDS(7)
	};
#endif

struct XSLighting
{
	half4 albedo;
	half4 normalMap;
	half4 detailNormal;
	half4 detailMask;
	half4 metallicGlossMap;
	half4 specularMap;

	half attenuation;
	half3 normal;
	half3 tangent;
	half3 bitangent;
	half4 worldPos;

	half alpha;
	float isOutline;
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
};

sampler2D _MainTex; half4 _MainTex_ST;
sampler2D _BumpMap; half4 _BumpMap_ST;
sampler2D _DetailNormalMap; half4 _DetailNormalMap_ST;
sampler2D _DetailMask; half4 _DetailMask_ST;
sampler2D _SpecularMap; half4 _SpecularMap_ST;
sampler2D _MetallicGlossMap; half4 _MetallicGlossMap_ST;
sampler2D _Ramp;

half4 _Color, _ShadowColor, _ShadowRim, _OutlineColor;
half _ShadowRimRange, _ShadowRimThreshold, _ShadowRange;

half _Metallic, _Glossiness;
half _BumpScale, _DetailNormalMapScale;
half _SpecularIntensity, _SpecularArea, _AnisotropicAX, _AnisotropicAY;
half _RimRange, _RimThreshold, _RimIntensity;
half _ShadowSharpness;
half _Cutoff;

half _OutlineWidth;

int _RampMode, _SpecMode, _SpecularStyle, _ShadowSteps;

int _UVSetAlbedo, _UVSetNormal, _UVSetDetNormal, 
	_UVSetDetMask, _UVSetMetallic, _UVSetSpecular;

