using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using System;


public class XSToonInspector : ShaderGUI
{

	//Material Properties
	MaterialProperty _Culling;
	MaterialProperty _MainTex;
	MaterialProperty _Color;
	MaterialProperty _Cutoff;
	MaterialProperty _BumpMap;
	MaterialProperty _BumpScale;
	MaterialProperty _DetailNormalMap;
	MaterialProperty _DetailMask;
	MaterialProperty _DetailNormalMapScale;
	MaterialProperty _ReflectionMode;
	MaterialProperty _MetallicGlossMap;
	MaterialProperty _BakedCubemap;
	MaterialProperty _Matcap;
	MaterialProperty _ReflectivityMask;
	MaterialProperty _Metallic;
	MaterialProperty _Glossiness;
	MaterialProperty _EmissionMap;
	MaterialProperty _EmissionColor;
	MaterialProperty _RimIntensity;
	MaterialProperty _RimRange;
	MaterialProperty _RimThreshold;
	MaterialProperty _RimSharpness;
	MaterialProperty _SpecMode;
	MaterialProperty _SpecularStyle;
	MaterialProperty _SpecularMap;
	MaterialProperty _SpecularIntensity;
	MaterialProperty _SpecularArea;
	MaterialProperty _AnisotropicAX;
	MaterialProperty _AnisotropicAY;
	MaterialProperty _Ramp;
	MaterialProperty _ShadowRim;
	MaterialProperty _ShadowRimRange;
	MaterialProperty _ShadowRimThreshold;
	MaterialProperty _ShadowRimSharpness;
	MaterialProperty _OcclusionMap;
	MaterialProperty _OcclusionColor;
	MaterialProperty _ThicknessMap;
	MaterialProperty _SSColor;
	MaterialProperty _SSDistortion;
	MaterialProperty _SSPower;
	MaterialProperty _SSScale;
	MaterialProperty _SSSRange;
	MaterialProperty _SSSSharpness;
	MaterialProperty _HalftoneDotSize;
	MaterialProperty _HalftoneDotAmount;
	MaterialProperty _HalftoneLineAmount;
	MaterialProperty _UVSetAlbedo;
	MaterialProperty _UVSetNormal;
	MaterialProperty _UVSetDetNormal;
	MaterialProperty _UVSetDetMask;
	MaterialProperty _UVSetMetallic;
	MaterialProperty _UVSetSpecular;
	MaterialProperty _UVSetReflectivity;
	MaterialProperty _UVSetThickness;
	MaterialProperty _UVSetOcclusion;
	MaterialProperty _UVSetEmission;
	MaterialProperty _Stencil;
	MaterialProperty _StencilComp;
	MaterialProperty _StencilOp;
	MaterialProperty _OutlineWidth;
	MaterialProperty _OutlineColor;
	MaterialProperty _ShadowSharpness;
	MaterialProperty _AdvMode;

	static bool isAdvancedMode = false;

	static bool showMainSettings = true;
	static bool showNormalMapSettings = false;
	static bool showShadows = true;
	static bool showSpecular = false;
	static bool showReflection = false;
	static bool showRimlight = false;
	static bool showSubsurface = false;
	static bool showOutlines = false;
	static bool showEmission = false;
	static bool showAdvanced = false;

	bool isOutlined = false;
	bool isCutout = false;

	public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
	{
		Material material = materialEditor.target as Material;
		Shader shader = material.shader;

		isCutout = shader.name.Contains("Cutout");
		isOutlined = shader.name.Contains("Outline");

		_Culling = FindProperty("_Culling", props);
		_MainTex = FindProperty("_MainTex", props);
		_Color = FindProperty("_Color", props);
		_Cutoff = FindProperty("_Cutoff", props);
		_BumpMap = FindProperty("_BumpMap", props);
		_BumpScale = FindProperty("_BumpScale", props);
		_DetailNormalMap = FindProperty("_DetailNormalMap", props);
		_DetailMask = FindProperty("_DetailMask", props);
		_DetailNormalMapScale = FindProperty("_DetailNormalMapScale", props);
		_ReflectionMode = FindProperty("_ReflectionMode", props);
		_MetallicGlossMap = FindProperty("_MetallicGlossMap", props);
		_BakedCubemap = FindProperty("_BakedCubemap", props);
		_Matcap = FindProperty("_Matcap", props);
		_ReflectivityMask = FindProperty("_ReflectivityMask", props);
		_Metallic = FindProperty("_Metallic", props);
		_Glossiness = FindProperty("_Glossiness", props);
		_EmissionMap = FindProperty("_EmissionMap", props);
		_EmissionColor = FindProperty("_EmissionColor", props);
		_RimIntensity = FindProperty("_RimIntensity", props);
		_RimRange = FindProperty("_RimRange", props);
		_RimThreshold = FindProperty("_RimThreshold", props);
		_RimSharpness = FindProperty("_RimSharpness", props);
		_SpecMode = FindProperty("_SpecMode", props);
		_SpecularStyle = FindProperty("_SpecularStyle", props);
		_SpecularMap = FindProperty("_SpecularMap", props);
		_SpecularIntensity = FindProperty("_SpecularIntensity", props);
		_SpecularArea = FindProperty("_SpecularArea", props);
		_AnisotropicAX = FindProperty("_AnisotropicAX", props);
		_AnisotropicAY = FindProperty("_AnisotropicAY", props);
		_Ramp = FindProperty("_Ramp", props);
		_ShadowRim = FindProperty("_ShadowRim", props);
		_ShadowRimRange = FindProperty("_ShadowRimRange", props);
		_ShadowRimThreshold = FindProperty("_ShadowRimThreshold", props);
		_ShadowRimSharpness = FindProperty("_ShadowRimSharpness", props);
		_ShadowSharpness = FindProperty("_ShadowSharpness", props);
		_OcclusionMap = FindProperty("_OcclusionMap", props);
		_OcclusionColor = FindProperty("_OcclusionColor", props);
		_ThicknessMap = FindProperty("_ThicknessMap", props);
		_SSColor = FindProperty("_SSColor", props);
		_SSDistortion = FindProperty("_SSDistortion", props);
		_SSPower = FindProperty("_SSPower", props);
		_SSScale = FindProperty("_SSScale", props);
		_SSSRange = FindProperty("_SSSRange", props);
		_SSSSharpness = FindProperty("_SSSSharpness", props);
		_HalftoneDotSize = FindProperty("_HalftoneDotSize", props);
		_HalftoneDotAmount = FindProperty("_HalftoneDotAmount", props);
		_HalftoneLineAmount = FindProperty("_HalftoneLineAmount", props);
		_UVSetAlbedo = FindProperty("_UVSetAlbedo", props);
		_UVSetNormal = FindProperty("_UVSetNormal", props);
		_UVSetDetNormal = FindProperty("_UVSetDetNormal", props);
		_UVSetDetMask = FindProperty("_UVSetDetMask", props);
		_UVSetMetallic = FindProperty("_UVSetMetallic", props);
		_UVSetSpecular = FindProperty("_UVSetSpecular", props);
		_UVSetReflectivity = FindProperty("_UVSetReflectivity", props);
		_UVSetThickness = FindProperty("_UVSetThickness", props);
		_UVSetOcclusion = FindProperty("_UVSetOcclusion", props);
		_UVSetEmission = FindProperty("_UVSetEmission", props);
		_Stencil = FindProperty("_Stencil", props);
		_StencilComp = FindProperty("_StencilComp", props);
		_StencilOp = FindProperty("_StencilOp", props);
		_AdvMode = ShaderGUI.FindProperty("_AdvMode", props);

		if (isOutlined)
		{
			_OutlineWidth = FindProperty("_OutlineWidth", props);
			_OutlineColor = FindProperty("_OutlineColor", props);
		}

		EditorGUI.BeginChangeCheck();
		{
			materialEditor.ShaderProperty(_AdvMode, _AdvMode.displayName);
			showMainSettings = XSStyles.ShurikenFoldout("Main Settings", showMainSettings);
			if (showMainSettings)
			{
				materialEditor.TexturePropertySingleLine(new GUIContent("Main Texture", "The Main Texture."), _MainTex, _Color);
				if (isCutout)
				{
					materialEditor.ShaderProperty(_Cutoff, new GUIContent("Cutoff", "The Cutoff Amount"), 2);
				}
				materialEditor.ShaderProperty(_UVSetAlbedo, new GUIContent("UV Set", "The UV set to use for the Albedo Texture"), 2);
				materialEditor.TextureScaleOffsetProperty(_MainTex);
				materialEditor.ShaderProperty(_Culling, _Culling.displayName);
			}

			if(!isCutout)
			{
				material.SetFloat("_Cutoff", 0.5f);
			}

			showShadows = XSStyles.ShurikenFoldout("Shadows", showShadows);
			if(showShadows)
			{
				materialEditor.TexturePropertySingleLine(new GUIContent("Shadow Ramp", "Shadow Ramp, Dark to Light should be Left to Right, or Down to Up"), _Ramp);
				materialEditor.ShaderProperty(_ShadowSharpness, new GUIContent("Shadow Sharpness", "Only affects recieved shadows and self shadows. Does not affect shadow ramp. You need a realtime directional light with shadows to see changes from this!"));

				GUILayout.Space(5);
				materialEditor.TexturePropertySingleLine(new GUIContent("Occlusion Map", "Occlusion Map, used to darken areas on the model artifically."), _OcclusionMap);
				XSStyles.constrainedShaderProperty(materialEditor, _OcclusionColor, new GUIContent("Occlusion Tint", "Occlusion shadow tint."), 2);
				materialEditor.ShaderProperty(_UVSetOcclusion, new GUIContent("UV Set", "The UV set to use for the Occlusion Texture"), 2);

				GUILayout.Space(5);
				XSStyles.constrainedShaderProperty(materialEditor, _ShadowRim, new GUIContent("Shadow Rim", "Shadow Rim Color. Set to white to disable."), 0);
				materialEditor.ShaderProperty(_ShadowRimRange, new GUIContent("Range", "Range of the Shadow Rim"), 2);
				materialEditor.ShaderProperty(_ShadowRimThreshold, new GUIContent("Threshold", "Threshold of the Shadow Rim"), 2);
				materialEditor.ShaderProperty(_ShadowRimSharpness, new GUIContent("Sharpness", "Sharpness of the Shadow Rim"), 2);
				XSStyles.callGradientEditor();
			}

			if (isOutlined)
			{
				showOutlines = XSStyles.ShurikenFoldout("Outlines", showOutlines);
				if (showOutlines)
				{
					materialEditor.ShaderProperty(_OutlineWidth, new GUIContent("Outline Width", "Width of the Outlines"));
					XSStyles.constrainedShaderProperty(materialEditor, _OutlineColor, new GUIContent("Outline Color", "Color of the outlines"), 0);
				}
			}

			showNormalMapSettings = XSStyles.ShurikenFoldout("Normal Maps", showNormalMapSettings);
			if (showNormalMapSettings)
			{
				
				materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map", "Normal Map"), _BumpMap);
				materialEditor.ShaderProperty(_BumpScale, new GUIContent("Normal Strength", "Strength of the main Normal Map"), 2);
				materialEditor.ShaderProperty(_UVSetNormal, new GUIContent("UV Set", "The UV set to use for the Normal Map"), 2);
				materialEditor.TextureScaleOffsetProperty(_BumpMap);

				materialEditor.TexturePropertySingleLine(new GUIContent("Detail Normal Map", "Detail Normal Map"), _DetailNormalMap);
				materialEditor.ShaderProperty(_DetailNormalMapScale, new GUIContent("Detail Normal Strength", "Strength of the detail Normal Map"), 2);
				materialEditor.ShaderProperty(_UVSetDetNormal, new GUIContent("UV Set", "The UV set to use for the Detail Normal Map"), 2);
				materialEditor.TextureScaleOffsetProperty(_DetailNormalMap);
			}

			showEmission = XSStyles.ShurikenFoldout("Emission", showEmission);
			if(showEmission)
			{
				materialEditor.TexturePropertySingleLine(new GUIContent("Emission Map", "Emissive map. White to black, unless you want multiple colors."), _EmissionMap, _EmissionColor);
				materialEditor.ShaderProperty(_UVSetEmission, new GUIContent("UV Set", "The UV set to use for the Emission Map"), 2);
				materialEditor.TextureScaleOffsetProperty(_EmissionMap);
			}

			showRimlight = XSStyles.ShurikenFoldout("Rimlight", showRimlight);
			if (showRimlight)
			{
				materialEditor.ShaderProperty(_RimIntensity, new GUIContent("Rimlight Intensity", "Strnegth of the Rimlight."));
				materialEditor.ShaderProperty(_RimRange, new GUIContent("Range", "Range of the Rim"), 2);
				materialEditor.ShaderProperty(_RimThreshold, new GUIContent("Threshold", "Threshold of the Rim"), 2);
				materialEditor.ShaderProperty(_RimSharpness, new GUIContent("Sharpness", "Sharpness of the Rim"), 2);
			}

			showSpecular = XSStyles.ShurikenFoldout("Specular", showSpecular);
			if (showSpecular)
			{
				materialEditor.ShaderProperty(_SpecMode, new GUIContent("Specular Mode", "Specular Mode."));
				materialEditor.ShaderProperty(_SpecularStyle, new GUIContent("Specular Style", "Specular Style."));
				materialEditor.TexturePropertySingleLine(new GUIContent("Specular Map", "Specular Map"), _SpecularMap);
				materialEditor.TextureScaleOffsetProperty(_SpecularMap);
				materialEditor.ShaderProperty(_UVSetSpecular, new GUIContent("UV Set", "The UV set to use for the Specular Map"), 2);
				materialEditor.ShaderProperty(_SpecularIntensity, new GUIContent("Specular Intesnity", "Specular Intensity."), 2);

				if (_SpecMode.floatValue == 0 || _SpecMode.floatValue == 2)
				{
					materialEditor.ShaderProperty(_SpecularArea, new GUIContent("Specular Area", "Specular Area."), 2);
				}
				else
				{
					materialEditor.ShaderProperty(_AnisotropicAX, new GUIContent("Anisotropic Width", "Anisotropic Width"), 2);
					materialEditor.ShaderProperty(_AnisotropicAY, new GUIContent("Anisotropic Height", "Anisotropic Height"), 2);
				}
			}

			showReflection = XSStyles.ShurikenFoldout("Reflections", showReflection);
			if (showReflection)
			{
				materialEditor.ShaderProperty(_ReflectionMode, new GUIContent("Reflection Mode", "Reflection Mode."));
				if (_ReflectionMode.floatValue == 0) // PBR
				{
					materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map", "Metallic Map, Metallic on Red Channel, Smoothness on Alpha Channel"), _MetallicGlossMap);
					materialEditor.TextureScaleOffsetProperty(_MetallicGlossMap);
					materialEditor.TexturePropertySingleLine(new GUIContent("Fallback Cubemap", " Used as fallback in 'Unity' reflection mode if reflection probe is black."), _BakedCubemap);
				}
				else if (_ReflectionMode.floatValue == 1) //Baked cube
				{
					materialEditor.TextureScaleOffsetProperty(_MetallicGlossMap);
					materialEditor.TexturePropertySingleLine(new GUIContent("Metallic Map", "Metallic Map, Metallic on Red Channel, Smoothness on Alpha Channel"), _MetallicGlossMap);
					materialEditor.TexturePropertySingleLine(new GUIContent("Baked Cubemap", "Baked cubemap."), _BakedCubemap);
				}
				else if (_ReflectionMode.floatValue == 2) //Matcap
				{
					materialEditor.TexturePropertySingleLine(new GUIContent("Matcap", "Matcap Texture"), _Matcap);
				}
				if (_ReflectionMode.floatValue != 3)
				{
					
					materialEditor.TexturePropertySingleLine(new GUIContent("Reflectivity Mask", "Mask for reflections."), _ReflectivityMask);
					materialEditor.TextureScaleOffsetProperty(_ReflectivityMask);
					materialEditor.ShaderProperty(_UVSetReflectivity, new GUIContent("UV Set", "The UV set to use for the Reflectivity Mask"), 2);
					materialEditor.ShaderProperty(_Metallic, new GUIContent("Metallic", "Metallic, set to 1 if using metallic map"), 2);
					materialEditor.ShaderProperty(_Glossiness, new GUIContent("Smoothness", "Smoothness, set to 1 if using metallic map"), 2);
				}
			}

			showSubsurface = XSStyles.ShurikenFoldout("Subsurface Scattering", showSubsurface);
			if(showSubsurface)
			{
				materialEditor.TexturePropertySingleLine(new GUIContent("Thickness Map", "Thickness Map, used to mask areas where subsurface can happen"), _ThicknessMap);
				materialEditor.TextureScaleOffsetProperty(_ThicknessMap);
				materialEditor.ShaderProperty(_UVSetThickness, new GUIContent("UV Set", "The UV set to use for the Thickness Map"), 2);
				
				XSStyles.constrainedShaderProperty(materialEditor, _SSColor, new GUIContent("Subsurface Color", "Subsurface Scattering Color"), 2);
				materialEditor.ShaderProperty(_SSDistortion, new GUIContent("Subsurface Distortion", "How much the subsurface follows the normals of the mesh, Normal map."), 2);
				materialEditor.ShaderProperty(_SSPower, new GUIContent("Subsurface Power", "Subsurface Power"), 2);
				materialEditor.ShaderProperty(_SSScale, new GUIContent("Subsurface Scale", "Subsurface Scale"), 2);
				materialEditor.ShaderProperty(_SSSRange, new GUIContent("Subsurface Range", "Subsurface Range"), 2);
				materialEditor.ShaderProperty(_SSSSharpness, new GUIContent("Subsurface Sharpness", "Subsurface Sharpness"), 2);
			}

			if (_AdvMode.floatValue == 1)
			{
				showAdvanced = XSStyles.ShurikenFoldout("Advanced Settings", showAdvanced);
				if (showAdvanced)
				{
					materialEditor.ShaderProperty(_Stencil, _Stencil.displayName);
					materialEditor.ShaderProperty(_StencilComp, _StencilComp.displayName);
					materialEditor.ShaderProperty(_StencilOp, _StencilOp.displayName);
				}
			}

			XSStyles.DoFooter();
		}
	}
}
//new GUIContent("", "")