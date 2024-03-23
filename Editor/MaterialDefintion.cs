using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace XSToon3
{
    public class Properties : ShaderGUI
    {
        public BindingFlags bindingFlags = BindingFlags.Public    |
                                           BindingFlags.NonPublic |
                                           BindingFlags.Instance  |
                                           BindingFlags.Static;
        
        public MaterialProperty _VertexColorAlbedo;
        public MaterialProperty _TilingMode;
        public MaterialProperty _Culling;
        public MaterialProperty _BlendMode;
        public MaterialProperty _MainTex;
        public MaterialProperty _HSVMask;
        public MaterialProperty _Saturation;
        public MaterialProperty _Hue;
        public MaterialProperty _Value;
        public MaterialProperty _Color;
        public MaterialProperty _Cutoff;
        public MaterialProperty _FadeDither;
        public MaterialProperty _FadeDitherDistance;
        public MaterialProperty _BumpMap;
        public MaterialProperty _BumpScale;
        public MaterialProperty _DetailNormalMap;
        public MaterialProperty _DetailMask;
        public MaterialProperty _DetailNormalMapScale;
        public MaterialProperty _ReflectionMode;
        public MaterialProperty _ReflectionBlendMode;
        public MaterialProperty _MetallicGlossMap;
        public MaterialProperty _BakedCubemap;
        public MaterialProperty _Matcap;
        public MaterialProperty _MatcapTintToDiffuse;
        public MaterialProperty _MatcapTint;
        public MaterialProperty _ReflectivityMask;
        public MaterialProperty _Metallic;
        public MaterialProperty _Glossiness;
        public MaterialProperty _Reflectivity;
        public MaterialProperty _ClearCoat;
        public MaterialProperty _ClearcoatStrength;
        public MaterialProperty _ClearcoatSmoothness;
        public MaterialProperty _EmissionMap;
        public MaterialProperty _ScaleWithLight;
        public MaterialProperty _ScaleWithLightSensitivity;
        public MaterialProperty _EmissionColor;
        public MaterialProperty _EmissionColor0;
        public MaterialProperty _EmissionColor1;
        public MaterialProperty _EmissionToDiffuse;
        public MaterialProperty _RimColor;
        public MaterialProperty _RimIntensity;
        public MaterialProperty _RimRange;
        public MaterialProperty _RimThreshold;
        public MaterialProperty _RimSharpness;
        public MaterialProperty _RimAlbedoTint;
        public MaterialProperty _RimCubemapTint;
        public MaterialProperty _RimAttenEffect;
        public MaterialProperty _SpecularSharpness;
        public MaterialProperty _SpecularMap;
        public MaterialProperty _SpecularIntensity;
        public MaterialProperty _SpecularArea;
        public MaterialProperty _AnisotropicSpecular;
        public MaterialProperty _AnisotropicReflection;
        public MaterialProperty _SpecularAlbedoTint;
        public MaterialProperty _ShadowMapTexture;
        public MaterialProperty _UseShadowMapTexture;
        public MaterialProperty _RampSelectionMask;
        public MaterialProperty _Ramp;
        public MaterialProperty _RimMask;
        public MaterialProperty _ShadowRim;
        public MaterialProperty _ShadowRimRange;
        public MaterialProperty _ShadowRimThreshold;
        public MaterialProperty _ShadowRimSharpness;
        public MaterialProperty _ShadowRimAlbedoTint;
        public MaterialProperty _OcclusionMap;
        public MaterialProperty _OcclusionIntensity;
        public MaterialProperty _OcclusionMode;
        public MaterialProperty _ThicknessMap;
        public MaterialProperty _SSColor;
        public MaterialProperty _SSDistortion;
        public MaterialProperty _SSPower;
        public MaterialProperty _SSScale;
        public MaterialProperty _HalftoneDotSize;
        public MaterialProperty _HalftoneDotAmount;
        public MaterialProperty _HalftoneLineAmount;
        public MaterialProperty _HalftoneLineIntensity;
        public MaterialProperty _HalftoneType;
        public MaterialProperty _UVSetAlbedo;
        public MaterialProperty _UVSetNormal;
        public MaterialProperty _UVSetDetNormal;
        public MaterialProperty _UVSetDetMask;
        public MaterialProperty _UVSetMetallic;
        public MaterialProperty _UVSetSpecular;
        public MaterialProperty _UVSetReflectivity;
        public MaterialProperty _UVSetThickness;
        public MaterialProperty _UVSetOcclusion;
        public MaterialProperty _UVSetEmission;
        public MaterialProperty _UVSetClipMap;
        public MaterialProperty _UVSetDissolve;
        public MaterialProperty _UVSetRimMask;
        public MaterialProperty _Stencil;
        public MaterialProperty _StencilComp;
        public MaterialProperty _StencilOp;
        public MaterialProperty _OutlineAlbedoTint;
        public MaterialProperty _OutlineLighting;
        public MaterialProperty _OutlineMask;
        public MaterialProperty _OutlineWidth;
        public MaterialProperty _OutlineColor;
        public MaterialProperty _OutlineNormalMode;
        public MaterialProperty _OutlineUVSelect;
        public MaterialProperty _ShadowSharpness;
        public MaterialProperty _AdvMode;
        public MaterialProperty _UVDiscardMode;
        public MaterialProperty _UVDiscardChannel;
        public MaterialProperty _ClipMap;
        public MaterialProperty _ClipAgainstVertexColorGreaterZeroFive;
        public MaterialProperty _ClipAgainstVertexColorLessZeroFive;
        public MaterialProperty _IOR;
        public MaterialProperty _NormalMapMode;
        public MaterialProperty _DissolveCoordinates;
        public MaterialProperty _DissolveTexture;
        public MaterialProperty _DissolveStrength;
        public MaterialProperty _DissolveColor;
        public MaterialProperty _DissolveProgress;
        public MaterialProperty _UseClipsForDissolve;
        public MaterialProperty _WireColor;
        public MaterialProperty _WireWidth;
        public MaterialProperty _SrcBlend;
        public MaterialProperty _DstBlend;
        public MaterialProperty _ZWrite;


        public MaterialProperty _EmissionAudioLinkChannel;
        public MaterialProperty _ALGradientOnRed;
        public MaterialProperty _ALGradientOnGreen;
        public MaterialProperty _ALGradientOnBlue;
        public MaterialProperty _ALUVWidth;

        //Experimenting
        public MaterialProperty _DissolveBlendPower;
        public MaterialProperty _DissolveLayer1Scale;
        public MaterialProperty _DissolveLayer2Scale;
        public MaterialProperty _DissolveLayer1Speed;
        public MaterialProperty _DissolveLayer2Speed;
        public MaterialProperty _ClipMask;
        public MaterialProperty _ClipIndex;
        public MaterialProperty _ClipSlider00;
        public MaterialProperty _ClipSlider01;
        public MaterialProperty _ClipSlider02;
        public MaterialProperty _ClipSlider03;
        public MaterialProperty _ClipSlider04;
        public MaterialProperty _ClipSlider05;
        public MaterialProperty _ClipSlider06;
        public MaterialProperty _ClipSlider07;
        public MaterialProperty _ClipSlider08;
        public MaterialProperty _ClipSlider09;
        public MaterialProperty _ClipSlider10;
        public MaterialProperty _ClipSlider11;
        public MaterialProperty _ClipSlider12;
        public MaterialProperty _ClipSlider13;
        public MaterialProperty _ClipSlider14;
        public MaterialProperty _ClipSlider15;

        //Material Properties for Eye tracking Plugins
        public MaterialProperty _LeftRightPan;
        public MaterialProperty _UpDownPan;
        public MaterialProperty _Twitchyness;
        public MaterialProperty _AttentionSpan;
        public MaterialProperty _FollowPower;
        public MaterialProperty _FollowLimit;
        public MaterialProperty _LookSpeed;
        public MaterialProperty _IrisSize;
        public MaterialProperty _EyeOffsetLimit;
        //--

        //Properties for Fur plugin
        public MaterialProperty _FurMode;
        public MaterialProperty _FurTexture;
        public MaterialProperty _FurLengthMask;
        public MaterialProperty _NoiseTexture;
        public MaterialProperty _LayerCount;
        public MaterialProperty _FurLength;
        public MaterialProperty _FurWidth;
        public MaterialProperty _Gravity;
        public MaterialProperty _CombX;
        public MaterialProperty _CombY;
        public MaterialProperty _ColorFalloffMin;
        public MaterialProperty _ColorFalloffMax;
        public MaterialProperty _BottomColor;
        public MaterialProperty _TopColor;
        public MaterialProperty _StrandAmount;
        public MaterialProperty _FurWidthRandomness;
        public MaterialProperty _FurLengthRandomness;
        public MaterialProperty _FurMessiness;
        //
        
        //!RDPSPropsInjection

        public void GetProperties(ref MaterialProperty[] props)
        {
            //Find all material properties listed in the script using reflection, and set them using a loop only if they're of type MaterialProperty.
            //This makes things a lot nicer to maintain and cleaner to look at.
            foreach (var property in GetType().GetFields(bindingFlags))
            {
                if (property.FieldType == typeof(MaterialProperty))
                {
                    try
                    {
                        property.SetValue(this, FindProperty(property.Name, props));
                    }
                    catch
                    {
                        /*Is it really a problem if it doesn't exist?*/
                    }
                }
            }
        }
    }
    
    public class MaterialInspector
    {
        public Properties MaterialProperties = new Properties();

        public bool OverrideRenderSettings = false;
        public Enums.AlphaMode BlendMode;
        public Enums.ShaderTypeFlags ShaderType;
        
        // Stuff for UV Discard because toggles are cursed when you want to draw a grid in editor
        public bool DiscardTile0 = false;
        public bool DiscardTile1 = false;
        public bool DiscardTile2 = false;
        public bool DiscardTile3 = false;
        public bool DiscardTile4 = false;
        public bool DiscardTile5 = false;
        public bool DiscardTile6 = false;
        public bool DiscardTile7 = false;
        public bool DiscardTile8 = false;
        public bool DiscardTile9 = false;
        public bool DiscardTile10 = false;
        public bool DiscardTile11 = false;
        public bool DiscardTile12 = false;
        public bool DiscardTile13 = false;
        public bool DiscardTile14 = false;
        public bool DiscardTile15 = false;
        //

        private void GetShaderFlags(Material material)
        {
            Shader shader = material.shader;
            BlendMode = (Enums.AlphaMode)material.GetInt("_BlendMode");

            switch (BlendMode)
            {
                case Enums.AlphaMode.Opaque:
                    ShaderType |= Enums.ShaderTypeFlags.Standard;
                    break;
                case Enums.AlphaMode.Cutout:
                    ShaderType |= Enums.ShaderTypeFlags.Cutout;
                    break;
                case Enums.AlphaMode.Dithered:
                    ShaderType |= Enums.ShaderTypeFlags.Dithered;
                    break;
                case Enums.AlphaMode.AlphaToCoverage:
                    ShaderType |= Enums.ShaderTypeFlags.AlphaToCoverage;
                    break;
            }
            
            if (shader.name.Contains("Outline"))
            {
                ShaderType |= Enums.ShaderTypeFlags.Outlined;
            }

            if (shader.name.Contains("EyeTracking"))
            {
                ShaderType |= Enums.ShaderTypeFlags.EyeTracking;
            }

            if (shader.name.Contains("Fur"))
            {
                ShaderType |= Enums.ShaderTypeFlags.Fur;
            }
        }

        public void DoMaterialSettings(Material material, ref MaterialProperty[] props)
        {
            GetShaderFlags(material);
            MaterialProperties.GetProperties(ref props);        }

        public bool HasTypeFlag(Enums.ShaderTypeFlags shaderTypeFlag)
        {
            return ShaderType.HasFlag(shaderTypeFlag);
        }

        public bool ShaderSupportsClipping(Material material)
        {
            return HasTypeFlag(Enums.ShaderTypeFlags.Cutout) || HasTypeFlag(Enums.ShaderTypeFlags.Dithered) || HasTypeFlag(Enums.ShaderTypeFlags.AlphaToCoverage);
        }
    }
}