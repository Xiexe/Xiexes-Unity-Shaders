Shader "Xiexe/Toon3/XSToon3_Iridescent"
{
    Properties
    {
        [Enum(Off, 0, On, 1)] _VertexColorAlbedo ("Vertex Color Albedo", Int) = 0
        [Enum(Separated, 0, Merged, 1)] _TilingMode ("Tiling Mode", Int) = 0
        [Enum(Off,0,Front,1,Back,2)] _Culling ("Culling Mode", Int) = 2
        [Enum(Opaque, 0, Cutout, 1, Dithered, 2, Alpha To Coverage, 3, Transparent, 4, Fade, 5, Additive, 6)]_BlendMode("Blend Mode", Int) = 0

        _MainTex("Texture", 2D) = "white" {}
        _HSVMask("HSV Mask", 2D) = "white" {}
        _Hue("Hue", Range(0,1)) = 0
        _Saturation("Main Texture Saturation", Range(0,3)) = 1
        _Value("Value", Range(0,3)) = 1

        _Color("Color Tint", Color) = (1,1,1,1)
        _Cutoff("Cutoff", Float) = 0.5

        [ToggleUI]_FadeDither("Dither Distance Fading", Float) = 0
        _FadeDitherDistance("Fade Dither Distance", Float) = 0

        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Range(-2,2)) = 1

        [Enum(Texture,0,Vertex Colors,1)] _NormalMapMode ("Normal Map Mode", Int) = 0
        _DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
        _DetailMask("Detail Mask", 2D) = "white" {}
        _DetailNormalMapScale("Detail Normal Scale", Range(-2,2)) = 1.0

        [Enum(PBR(Unity Metallic Standard),0,Baked Cubemap,1,Matcap,2,Off,3)] _ReflectionMode ("Reflection Mode", Int) = 3
        [Enum(Disabled,0, Enabled, 1)]_ClearCoat("ClearCoat", Int) = 0
        [Enum(Additive,0,Multiply,1,Subtract,2)] _ReflectionBlendMode("Reflection Blend Mode", Int) = 0
        _MetallicGlossMap("Metallic", 2D) = "white" {} //Metallic, 0, 0, Smoothness
        _BakedCubemap("Baked Cubemap", CUBE) = "black" {}
        _Matcap("Matcap", 2D) = "black" {}
        [HDR]_MatcapTint("Matcap Tint", Color) = (1,1,1,1)
        _MatcapTintToDiffuse("Matcap Tint To Diffuse", Range(0,1)) = 0
        _ReflectivityMask("Reflection Mask" , 2D) = "white" {}
        _Metallic("Metallic", Range(0,1)) = 0
        _Glossiness("Smoothness", Range(0,1)) = 0
        _Reflectivity("Reflectivity", Range(0,1)) = 0.5
        _IOR("Index of Refraction", Range(1, 4)) = 0
        _ClearcoatStrength("Clearcoat Reflectivity", Range(0, 1)) = 1
        _ClearcoatSmoothness("Clearcoat Smoothness", Range(0, 1)) = 0.8

        [Enum(Yes,0, No,1)] _ScaleWithLight("Emission Scale w/ Light", Int) = 1
        _EmissionMap("Emission Map", 2D) = "white" {}
        _EmissionToDiffuse("Emission Tint To Diffuse", Range(0,1)) = 0
        _ScaleWithLightSensitivity("Scaling Sensitivity", Range(0,1)) = 1

        _RimColor("Rimlight Tint", Color) = (1,1,1,1)
        _RimAlbedoTint("Rim Albedo Tint", Range(0,1)) = 0
        _RimCubemapTint("Rim Environment Tint", Range(0,1)) = 0
        _RimAttenEffect("Rim Attenuation Effect", Range(0,1)) = 1
        _RimIntensity("Rimlight Intensity", Float) = 0
        _RimRange("Rim Range", Range(0,1)) = 0.7
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1
        _RimSharpness("Rim Sharpness", Range(0,1)) = 0.1

        _SpecularSharpness("Specular Sharpness", Range(0,1)) = 0
        _SpecularMap("Specular Map", 2D) = "white" {}
        _SpecularIntensity("Specular Intensity", Float) = 0
        _SpecularArea("Specular Smoothness", Range(0,1)) = 0.5
        _AnisotropicSpecular("Specular Anisotropic", Range(-1,1)) = 0
        _AnisotropicReflection("Reflection Anisotropic", Range(-1,1)) = 0
        _SpecularAlbedoTint("Specular Albedo Tint", Range(0,1)) = 1

        _RampSelectionMask("Ramp Mask", 2D) = "black" {}
        _Ramp("Shadow Ramp", 2D) = "white" {}
        _ShadowSharpness("Received Shadow Sharpness", Range(0,1)) = 0.5
        _ShadowRim("Shadow Rim Tint", Color) = (1,1,1,1)
        _ShadowRimRange("Shadow Rim Range", Range(0,1)) = 0.7
        _ShadowRimThreshold("Shadow Rim Threshold", Range(0, 1)) = 0.1
        _ShadowRimSharpness("Shadow Rim Sharpness", Range(0,1)) = 0.3
        _ShadowRimAlbedoTint("Shadow Rim Albedo Tint", Range(0, 1)) = 0

        [Enum(Indirect, 0, Integrated, 1)]_OcclusionMode("Occlusion Mode", Int) = 0
        _OcclusionMap("Occlusion", 2D) = "white" {}
        _OcclusionIntensity("Occlusion Intensity", Range(0,1)) = 1

        [Enum(Off, 0, On, 1)]_OutlineAlbedoTint("Outline Albedo Tint", Int) = 0
        [Enum(Lit, 0, Emissive, 1)]_OutlineLighting("Outline Lighting", Int) = 0
        [Enum(Mesh Normals, 0, Vertex Color Normals, 1, UVChannel, 2)]_OutlineNormalMode("Outline Normal Mode", Int) = 0
        [Enum(UV2, 1, UV3, 2)]_OutlineUVSelect("Altered Normal UV Channel", Int) = 2
        _OutlineMask("Outline Mask", 2D) = "white" {}
        _OutlineWidth("Outline Width", Range(0, 5)) = 1
        [HDR]_OutlineColor("Outline Color", Color) = (0,0,0,1)

        _ThicknessMap("Thickness Map", 2D) = "white" {}
        _SSColor ("Subsurface Color", Color) = (0,0,0,0)
        _SSDistortion("Normal Distortion", Range(0,3)) = 1
        _SSPower("Subsurface Power", Range(0,3)) = 1
        _SSScale("Subsurface Scale", Range(0,3)) = 1

        [Enum(Shadows, 0, Highlights, 1, Shadows And Highlights, 2, Off, 3)] _HalftoneType("Halftones Type", Int) = 3
        _HalftoneDotSize("Halftone Dot Size", Float) = 0.5
        _HalftoneDotAmount("Halftone Dot Amount", Float) = 5
        _HalftoneLineAmount("Halftone Line Amount", Float) = 2000
        _HalftoneLineIntensity("Halftone Line Intensity", Range(0,1)) = 1

        [Enum(UV, 0, Root Distance (Spherical), 1, Height, 2)]_DissolveCoordinates("Dissolve Shape", Int) = 0
        _DissolveTexture("Dissolve Texture", 2D) = "black" {}
        _DissolveBlendPower("Layer Blend Power", Float) = 1
        _DissolveLayer1Scale("Layer1 Scale", Float) = 1
        _DissolveLayer2Scale("Layer2 Scale", Float) = 0.5
        _DissolveLayer1Speed("Layer1 Speed", Float) = 0
        _DissolveLayer2Speed("Layer2 Speed", Float) = 0

        _DissolveStrength("Dissolve Sharpness", Float) = 1
        [HDR]_DissolveColor("Dissolve Color", Color) = (1,1,1,1)
        _DissolveProgress("Dissolve Amount", Range(0,1)) = 0
        [ToggleUI]_UseClipsForDissolve("Do Dissolve", Int) = 0

        _ClipAgainstVertexColorGreaterZeroFive("Clip Vert Color > 0.5", Vector) = (1,1,1,1)
        _ClipAgainstVertexColorLessZeroFive("Clip Vert Color < 0.5", Vector) = (1,1,1,1)

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
        [Enum(UV1,0,UV2,1)] _UVSetClipMap("Clip Map UVs", Int) = 0
        [Enum(UV1,0,UV2,1)] _UVSetDissolve("Dissolve Map UVs", Int) = 0

        [Enum(None,0,Bass,1,Low Mids,2,High Mids,3,Treble,4,Packed Map,5,UV Based,6)]_EmissionAudioLinkChannel("Emisssion Audio Link Channel", int) = 0
        [ToggleUI]_ALGradientOnRed("Gradient Red", Int) = 0
        [ToggleUI]_ALGradientOnGreen("Gradient Green", Int) = 0
        [ToggleUI]_ALGradientOnBlue("Gradient Blue", Int) = 0
        [HDR]_EmissionColor("Emission Color", Color) = (0,0,0,0)
        [HDR]_EmissionColor0("Emission Packed Color 1", Color) = (0,0,0,0)
        [HDR]_EmissionColor1("Emission Packed Color 2", Color) = (0,0,0,0)
        [IntRange]_ALUVWidth("History Sample Amount", Range(0,128)) = 128
        
        _Iridescent("Iridescent Gardient", 2D) = "white" {}
        [HDR]_IridescentColor("Iridescent Color", Color) = (1,1,1,1)
        _IridescentRimPower("Iridescent Rim Power", Float) = 1
        _IridescentSamplingPow("Iridescent Sampling Power", Float) = 1

        _ClipMap("Clip Map", 2D) = "black" {}
        _WireColor("Wire Color", Color) = (0,0,0,0)
        _WireWidth("Wire Width", Float) = 0
        [HideInInspector][Enum(Basic, 0, Advanced, 1)]_AdvMode("Shader Mode", Int) = 0
        [IntRange] _Stencil ("Stencil ID [0;255]", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Int) = 0

        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("__src", int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend ("__dst", int) = 0
        [Enum(Off,0,On,1)]_ZWrite ("__zw", int) = 1
        [HideInInspector] _AlphaToMask("__am", int) = 0

        _ClipMask("Clip Mask", 2D) = "black" {}
        [IntRange]_ClipIndex("Clip Index", Range(0,7)) = 0
        _ClipSlider00("", Vector) = (0,0,0,0)
        _ClipSlider01("", Vector) = (0,0,0,0)
        _ClipSlider02("", Vector) = (0,0,0,0)
        _ClipSlider03("", Vector) = (0,0,0,0)
        _ClipSlider04("", Vector) = (0,0,0,0)
        _ClipSlider05("", Vector) = (0,0,0,0)
        _ClipSlider06("", Vector) = (0,0,0,0)
        _ClipSlider07("", Vector) = (0,0,0,0)
        _ClipSlider08("", Vector) = (0,0,0,0)
        _ClipSlider09("", Vector) = (0,0,0,0)
        _ClipSlider10("", Vector) = (0,0,0,0)
        _ClipSlider11("", Vector) = (0,0,0,0)
        _ClipSlider12("", Vector) = (0,0,0,0)
        _ClipSlider13("", Vector) = (0,0,0,0)
        _ClipSlider14("", Vector) = (0,0,0,0)
        _ClipSlider15("", Vector) = (0,0,0,0)

        //!RDPSProps
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Cull [_Culling]
        AlphaToMask [_AlphaToMask]
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
        }
//        Grabpass // Gets disabled via the editor script when not in use through the Lightmode Tag.
//        {
//            Tags{"LightMode" = "Always"}
//            "_AudioTexture"
//        }
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            CGPROGRAM
            //#!RDPSTypeDefine
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ALPHABLEND_ON
            #pragma shader_feature _ALPHATEST_ON
            #pragma multi_compile _ VERTEXLIGHT_ON
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing

            #ifndef UNITY_PASS_FORWARDBASE
                #define UNITY_PASS_FORWARDBASE
            #endif

            #include "../../CGIncludes/AudioLink.cginc"
            #include "../../CGIncludes/XSDefines.cginc"
            #include  "XSIridescentDefines.cginc"
            #include "../../CGIncludes/XSHelperFunctions.cginc"
            #include "../../CGIncludes/XSLightingFunctions.cginc"
            #include "../../CGIncludes/XSLighting.cginc"
            #include "../../CGIncludes/XSPreLighting.cginc"
            #include "XSPostLighting.cginc"
            #include "../../CGIncludes/XSVert.cginc"
            #include "../../CGIncludes/XSFrag.cginc"
            ENDCG
        }

        Pass
        {
            Name "FWDADD"
            Tags { "LightMode" = "ForwardAdd" }
            Blend [_SrcBlend] One
            ZWrite Off
            ZTest LEqual
            Fog { Color (0,0,0,0) }
            CGPROGRAM
            //#!RDPSTypeDefine
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ALPHABLEND_ON
            #pragma shader_feature _ALPHATEST_ON
            #pragma multi_compile_fog
            #pragma multi_compile_fwdadd_fullshadows
            #ifndef UNITY_PASS_FORWARDADD
                 #define UNITY_PASS_FORWARDADD
            #endif

            #include "../../CGIncludes/AudioLink.cginc"
            #include "../../CGIncludes/XSDefines.cginc"
            #include  "XSIridescentDefines.cginc"
            #include "../../CGIncludes/XSHelperFunctions.cginc"
            #include "../../CGIncludes/XSLightingFunctions.cginc"
            #include "../../CGIncludes/XSLighting.cginc"
            #include "../../CGIncludes/XSPreLighting.cginc"
            #include "XSPostLighting.cginc"
            #include "../../CGIncludes/XSVert.cginc"
            #include "../../CGIncludes/XSFrag.cginc"
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }
            ZWrite On ZTest LEqual
            CGPROGRAM
            //#!RDPSTypeDefine
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ALPHABLEND_ON
            #pragma shader_feature _ALPHATEST_ON
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #ifndef UNITY_PASS_SHADOWCASTER
                #define UNITY_PASS_SHADOWCASTER
            #endif
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

            #include "../../CGIncludes/AudioLink.cginc"
            #include "../../CGIncludes/XSDefines.cginc"
            #include  "XSIridescentDefines.cginc"
            #include "../../CGIncludes/XSHelperFunctions.cginc"
            #include "../../CGIncludes/XSLightingFunctions.cginc"
            #include "../../CGIncludes/XSLighting.cginc"
            #include "../../CGIncludes/XSPreLighting.cginc"
            #include "XSPostLighting.cginc"
            #include "../../CGIncludes/XSVert.cginc"
            #include "../../CGIncludes/XSFrag.cginc"
            ENDCG
        }
    }
    Fallback "Diffuse"
    CustomEditor "XSToon3.XSToonIridescentInspector"
}
