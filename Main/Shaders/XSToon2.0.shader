﻿Shader "Unlit/XSToon2.0"
{
	Properties
	{	
		[Enum(Off,0,Front,1,Back,2)] _Culling ("Culling Mode", Int) = 2
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color Tint", Color) = (1,1,1,1)
		_Cutoff("Cutoff", Float) = 0.5

		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Scale", Float) = 1

		_DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
		_DetailMask("Detail Mask", 2D) = "white" {}
		_DetailNormalMapScale("Detail Normal Scale", Float) = 1.0

		_MetallicGlossMap("Metallic (M,O,_,S)", 2D) = "white" {}
		_Metallic("Metallic", Range(0,1)) = 0
		_Glossiness("Smoothness", Range(0,1)) = 0

		[Header(RimLight)]
		_RimIntensity("Rimlight Intensity", Float) = 1
		_RimRange("Rim Range", Range(0,1)) = 0.7
		_RimThreshold("Rim Threshold", Range(0, 1)) = 0.1

		[Header(Specularity)]
		[Enum(Blinn Phong, 0, Anisotropic, 1, GGX, 2)]_SpecMode("Specular Mode", Int) = 0
		[Enum(Smooth, 0, Sharp, 1)]_SpecularStyle("Specular Style", Int) = 0
		_SpecularMap("Specular Map", 2D) = "white" {}
		_SpecularIntensity("Specular Intensity", Float) = 1
		_SpecularArea("Specular Smoothness", Range(0,1)) = 0.5
		_AnisotropicAX("Anisotropic X", Range(0,1)) = 0.25
		_AnisotropicAY("Anisotripic Y", Range(0,1)) = 0.75  
		
		[Header(Shadows)]
		[Enum(Mixed Ramp Color, 0, Ramp Color, 1, Natural, 2)]_RampMode("Shadow Mode", Int) = 2
		_Ramp("Shadow Ramp", 2D) = "white" {}
		_ShadowColor("Shadow Tint", Color) = (1,1,1,1)
		_ShadowSharpness("Shadow Hardness", Range(0.001, 1)) = 0.2
		[IntRange]_ShadowSteps("Shadow Smoothness", Range(2,1024)) = 10
		_ShadowRim("Shadow Rim Tint", Color) = (1,1,1,1)
		_ShadowRimRange("Shadow Rim Range", Range(0,1)) = 0.7
		_ShadowRimThreshold("Shadow Rim Threshold", Range(0, 1)) = 0.1



		[Enum(UV1,0,UV2,1)] _UVSetAlbedo ("Albedo UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetNormal ("Normal Map UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetDetNormal ("Detail Normal UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetDetMask ("Detail Mask UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetMetallic ("Metallic Map UVs", Int) = 0
		[Enum(UV1,0,UV2,1)] _UVSetSpecular ("Specular Map UVs", Int) = 0
		
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		Cull [_Culling]
		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			//#define Geometry

			#pragma vertex vert
			//#pragma geometry geom
			#pragma fragment frag

			#pragma multi_compile_fwdbase 
			#pragma multi_compile UNITY_PASS_FORWARDBASE

			#include "../CGIncludes/XSDefines.cginc"
			#include "../CGIncludes/XSHelperFunctions.cginc"
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
			//#define Geometry

			#pragma vertex vert
			//#pragma geometry geom
			#pragma fragment frag

			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile UNITY_PASS_FORWARDADD
			
			#include "../CGIncludes/XSDefines.cginc"
			#include "../CGIncludes/XSHelperFunctions.cginc"
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
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

			#include "../CGIncludes/XSShadowCaster.cginc"
			ENDCG
		}
	}
	Fallback "Diffuse"
}
