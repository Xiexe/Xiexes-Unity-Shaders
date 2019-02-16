#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
#include "UnityCG.cginc"

struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;
};

struct v2f
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 ntb[3] : TEXCOORD1; //texcoord 2, 3 || Holds World Normal, Tangent, and Bitangent
	float4 worldPos : TEXCOORD6;
	SHADOW_COORDS(7)
};

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
	half3 worldNormal;
	half3 tangent;
	half3 bitangent;
	half4 worldPos;
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

half4 _Color;

half _Metallic, _Glossiness;
half _BumpScale, _DetailNormalMapScale;
half _SpecularIntensity, _SpecularArea, _AnisotropicAX, _AnisotropicAY;

int _RampMode, _SpecMode, _SpecularStyle;

