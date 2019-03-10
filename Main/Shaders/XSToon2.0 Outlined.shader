Shader "Xiexe/Toon2.0/XSToon2.0_Outlined"
{
	Properties
	{	
		[Enum(Off,0,Front,1,Back,2)] _Culling ("Culling Mode", Int) = 2
		_MainTex("Texture", 2D) = "white" {}
		_Saturation("Main Texture Saturation", Range(0,10)) = 1
		_Color("Color Tint", Color) = (1,1,1,1)
		_Cutoff("Cutoff", Float) = 0.5

		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Scale", Float) = 1

		_DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
		_DetailMask("Detail Mask", 2D) = "white" {}
		_DetailNormalMapScale("Detail Normal Scale", Float) = 1.0

		[Enum(PBR(Unity Metallic Standard),0,Baked Cubemap,1,Matcap,2,Off,3)] _ReflectionMode ("Reflection Mode", Int) = 3
		_MetallicGlossMap("Metallic", 2D) = "white" {} //Metallic, 0, 0, Smoothness
		_BakedCubemap("Baked Cubemap", CUBE) = "black" {}
		_Matcap("Matcap", 2D) = "black" {}
		_ReflectivityMask("Reflection Mask" , 2D) = "white" {}
		_Metallic("Metallic", Range(0,1)) = 0
		_Glossiness("Smoothness", Range(0,1)) = 0

		_EmissionMap("Emission Map", 2D) = "white" {}
		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,0)

		_RimIntensity("Rimlight Intensity", Float) = 0
		_RimRange("Rim Range", Range(0,1)) = 0.7
		_RimThreshold("Rim Threshold", Range(0, 1)) = 0.1
		_RimSharpness("Rim Sharpness", Range(0,1)) = 0.1


		[Enum(Blinn Phong, 0, Anisotropic, 1, GGX, 2)]_SpecMode("Specular Mode", Int) = 0
		[Enum(Smooth, 0, Sharp, 1)]_SpecularStyle("Specular Style", Int) = 0
		_SpecularMap("Specular Map", 2D) = "white" {}
		_SpecularIntensity("Specular Intensity", Float) = 0
		_SpecularArea("Specular Smoothness", Range(0,1)) = 0.5
		_AnisotropicAX("Anisotropic X", Range(0,1)) = 0.25
		_AnisotropicAY("Anisotripic Y", Range(0,1)) = 0.75  
		

		_Ramp("Shadow Ramp", 2D) = "white" {}
		_ShadowSharpness("Received Shadow Sharpness", Range(0,1)) = 0.5
		_ShadowRim("Shadow Rim Tint", Color) = (1,1,1,1)
		_ShadowRimRange("Shadow Rim Range", Range(0,1)) = 0.7
		_ShadowRimThreshold("Shadow Rim Threshold", Range(0, 1)) = 0.1
		_ShadowRimSharpness("Shadow Rim Sharpness", Range(0,1)) = 0.3
		
		_OcclusionMap("Occlusion", 2D) = "white" {}
		_OcclusionColor("Occlusion Color", Color) = (0,0,0,0)


		_OutlineWidth("Outline Width", Range(0, 5)) = 1
		_OutlineColor("Outline Color", Color) = (0,0,0,1) 


		_ThicknessMap("Thickness Map", 2D) = "white" {}
		_SSColor ("Subsurface Color", Color) = (0,0,0,0)
		_SSDistortion("Normal Distortion", Range(0,3)) = 1
		_SSPower("Subsurface Power", Range(0,3)) = 1
		_SSScale("Subsurface Scale", Range(0,3)) = 1
		_SSSRange("Subsurface Range", Range(0,1)) = 1
		_SSSSharpness("Subsurface Falloff", Range(0.001, 1)) = 0.2


		_HalftoneDotSize("Halftone Dot Size", Float) = 1.7
		_HalftoneDotAmount("Halftone Dot Amount", Float) = 50
		_HalftoneLineAmount("Halftone Line Amount", Float) = 150


		[Enum(UV1,0,UV2,1)] _UVSetAlbedo("Albedo UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetNormal("Normal Map UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetDetNormal("Detail Normal UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetDetMask("Detail Mask UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetMetallic("Metallic Map UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetSpecular("Specular Map UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetReflectivity("Reflection Mask UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetThickness("Thickness Map UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetOcclusion("Occlusion Map UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetEmission("Emission Map UVs", Int) = 0

		[HideInInspector][Enum(Basic, 0, Advanced, 1)]_AdvMode("Shader Mode", Int) = 0
		[IntRange] _Stencil ("Stencil ID [0;255]", Range(0,255)) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Int) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		Cull [_Culling]
				Stencil 
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [StencilOp]
		}
		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#define Geometry

			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#pragma multi_compile_fwdbase 
			//#pragma multi_compile UNITY_PASS_FORWARDBASE

			#include "../CGIncludes/XSDefines.cginc"
			#include "../CGIncludes/XSHelperFunctions.cginc"
			#include "../CGIncludes/XSLightingFunctions.cginc"
			#include "../CGIncludes/XSLighting.cginc"
			#include "../CGIncludes/XSVertFrag.cginc"
			ENDCG
		}

		Pass
		{
			Name "FWDADD"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One

			CGPROGRAM
			#define Geometry

			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#pragma multi_compile_fwdadd_fullshadows
			//#pragma multi_compile UNITY_PASS_FORWARDADD
			
			#include "../CGIncludes/XSDefines.cginc"
			#include "../CGIncludes/XSHelperFunctions.cginc"
			#include "../CGIncludes/XSLightingFunctions.cginc"
			#include "../CGIncludes/XSLighting.cginc"
			#include "../CGIncludes/XSVertFrag.cginc"
			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On ZTest LEqual
			CGPROGRAM
			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

			#include "../CGIncludes/XSShadowCaster.cginc"
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "XSToonInspector"
}
