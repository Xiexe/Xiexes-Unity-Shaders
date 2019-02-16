Shader "Unlit/XSToon2.0"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color Tint", Color) = (1,1,1,1)

		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Scale", Float) = 1

		_DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
		_DetailMask("Detail Mask", 2D) = "white" {}
		_DetailNormalMapScale("Detail Normal Scale", Float) = 1.0

		_MetallicGlossMap("Metallic (M, )", 2D) = "white" {}
		_Metallic("Metallic", Range(0,1)) = 0
		_Glossiness("Smoothness", Range(0,1)) = 0.5

		[Enum(Blinn Phong, 0, Anisotropic, 1, GGX, 2)]_SpecMode("Specular Mode", Int) = 0
		[Enum(Smooth, 0, Sharp, 1)]_SpecularStyle("Specular Style", Int) = 0
		_SpecularMap("Specular Map", 2D) = "white" {}
		_SpecularIntensity("Specular Intensity", Float) = 1
		_SpecularArea("Specular Smoothness", Range(0,1)) = 0.5

		_AnisotropicAX("Anisotropic X", Range(0,1)) = 0.25
		_AnisotropicAY("Anisotripic Y", Range(0,1)) = 0.75  
		
		[Enum(Mixed, 0, Ramp, 1)]_RampMode("Ramp Mode", Int) = 1
		_Ramp("Shadow Ramp", 2D) = "white" {}
		

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase 
			#pragma multi_compile UNITY_PASS_FORWARDBASE

			#include "XSDefines.cginc"
			#include "XSHelperFunctions.cginc"
			#include "XSLighting.cginc"
			#include "XSVertFrag.cginc"
			ENDCG
		}

		Pass
		{
			Name "FWDADD"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile UNITY_PASS_FORWARDADD
			
			#include "XSDefines.cginc"
			#include "XSHelperFunctions.cginc"
			#include "XSLighting.cginc"
			#include "XSVertFrag.cginc"
			ENDCG
		}
	}
	Fallback "Diffuse"
}
