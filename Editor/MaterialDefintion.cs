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
        
         //Assign all properties as null at first to stop hundreds of warnings spamming the log when script gets compiled.
        //If they aren't we get warnings, because assigning with reflection seems to make Unity think that the properties never actually get used.
        public MaterialProperty _VertexColorAlbedo = null;
        public MaterialProperty _TilingMode = null;
        public MaterialProperty _Culling = null;
        public MaterialProperty _BlendMode = null;
        public MaterialProperty _MainTex = null;
        public MaterialProperty _HSVMask = null;
        public MaterialProperty _Saturation = null;
        public MaterialProperty _Hue = null;
        public MaterialProperty _Value = null;
        public MaterialProperty _Color = null;
        public MaterialProperty _Cutoff = null;
        public MaterialProperty _FadeDither = null;
        public MaterialProperty _FadeDitherDistance = null;
        public MaterialProperty _BumpMap = null;
        public MaterialProperty _BumpScale = null;
        public MaterialProperty _DetailNormalMap = null;
        public MaterialProperty _DetailMask = null;
        public MaterialProperty _DetailNormalMapScale = null;
        public MaterialProperty _ReflectionMode = null;
        public MaterialProperty _ReflectionBlendMode = null;
        public MaterialProperty _MetallicGlossMap = null;
        public MaterialProperty _BakedCubemap = null;
        public MaterialProperty _Matcap = null;
        public MaterialProperty _MatcapTintToDiffuse = null;
        public MaterialProperty _MatcapTint = null;
        public MaterialProperty _ReflectivityMask = null;
        public MaterialProperty _Metallic = null;
        public MaterialProperty _Glossiness = null;
        public MaterialProperty _Reflectivity = null;
        public MaterialProperty _ClearCoat = null;
        public MaterialProperty _ClearcoatStrength = null;
        public MaterialProperty _ClearcoatSmoothness = null;
        public MaterialProperty _EmissionMap = null;
        public MaterialProperty _ScaleWithLight = null;
        public MaterialProperty _ScaleWithLightSensitivity = null;
        public MaterialProperty _EmissionColor = null;
        public MaterialProperty _EmissionColor0 = null;
        public MaterialProperty _EmissionColor1 = null;
        public MaterialProperty _EmissionToDiffuse = null;
        public MaterialProperty _RimColor = null;
        public MaterialProperty _RimIntensity = null;
        public MaterialProperty _RimRange = null;
        public MaterialProperty _RimThreshold = null;
        public MaterialProperty _RimSharpness = null;
        public MaterialProperty _RimAlbedoTint = null;
        public MaterialProperty _RimCubemapTint = null;
        public MaterialProperty _RimAttenEffect = null;
        public MaterialProperty _SpecularSharpness = null;
        public MaterialProperty _SpecularMap = null;
        public MaterialProperty _SpecularIntensity = null;
        public MaterialProperty _SpecularArea = null;
        public MaterialProperty _AnisotropicSpecular = null;
        public MaterialProperty _AnisotropicReflection = null;
        public MaterialProperty _SpecularAlbedoTint = null;
        public MaterialProperty _RampSelectionMask = null;
        public MaterialProperty _Ramp = null;
        public MaterialProperty _RimMask = null;
        public MaterialProperty _ShadowRim = null;
        public MaterialProperty _ShadowRimRange = null;
        public MaterialProperty _ShadowRimThreshold = null;
        public MaterialProperty _ShadowRimSharpness = null;
        public MaterialProperty _ShadowRimAlbedoTint = null;
        public MaterialProperty _OcclusionMap = null;
        public MaterialProperty _OcclusionIntensity = null;
        public MaterialProperty _OcclusionMode = null;
        public MaterialProperty _ThicknessMap = null;
        public MaterialProperty _SSColor = null;
        public MaterialProperty _SSDistortion = null;
        public MaterialProperty _SSPower = null;
        public MaterialProperty _SSScale = null;
        public MaterialProperty _HalftoneDotSize = null;
        public MaterialProperty _HalftoneDotAmount = null;
        public MaterialProperty _HalftoneLineAmount = null;
        public MaterialProperty _HalftoneLineIntensity = null;
        public MaterialProperty _HalftoneType = null;
        public MaterialProperty _UVSetAlbedo = null;
        public MaterialProperty _UVSetNormal = null;
        public MaterialProperty _UVSetDetNormal = null;
        public MaterialProperty _UVSetDetMask = null;
        public MaterialProperty _UVSetMetallic = null;
        public MaterialProperty _UVSetSpecular = null;
        public MaterialProperty _UVSetReflectivity = null;
        public MaterialProperty _UVSetThickness = null;
        public MaterialProperty _UVSetOcclusion = null;
        public MaterialProperty _UVSetEmission = null;
        public MaterialProperty _UVSetClipMap = null;
        public MaterialProperty _UVSetDissolve = null;
        public MaterialProperty _UVSetRimMask = null;
        public MaterialProperty _Stencil = null;
        public MaterialProperty _StencilComp = null;
        public MaterialProperty _StencilOp = null;
        public MaterialProperty _OutlineAlbedoTint = null;
        public MaterialProperty _OutlineLighting = null;
        public MaterialProperty _OutlineMask = null;
        public MaterialProperty _OutlineWidth = null;
        public MaterialProperty _OutlineColor = null;
        public MaterialProperty _OutlineNormalMode = null;
        public MaterialProperty _OutlineUVSelect = null;
        public MaterialProperty _ShadowSharpness = null;
        public MaterialProperty _AdvMode = null;
        public MaterialProperty _UVDiscardMode = null;
        public MaterialProperty _UVDiscardChannel = null;
        public MaterialProperty _ClipMap = null;
        public MaterialProperty _ClipAgainstVertexColorGreaterZeroFive = null;
        public MaterialProperty _ClipAgainstVertexColorLessZeroFive = null;
        public MaterialProperty _IOR = null;
        public MaterialProperty _NormalMapMode = null;
        public MaterialProperty _DissolveCoordinates = null;
        public MaterialProperty _DissolveTexture = null;
        public MaterialProperty _DissolveStrength = null;
        public MaterialProperty _DissolveColor = null;
        public MaterialProperty _DissolveProgress = null;
        public MaterialProperty _UseClipsForDissolve = null;
        public MaterialProperty _WireColor = null;
        public MaterialProperty _WireWidth = null;
        public MaterialProperty _SrcBlend = null;
        public MaterialProperty _DstBlend = null;
        public MaterialProperty _ZWrite = null;


        public MaterialProperty _EmissionAudioLinkChannel = null;
        public MaterialProperty _ALGradientOnRed = null;
        public MaterialProperty _ALGradientOnGreen = null;
        public MaterialProperty _ALGradientOnBlue = null;
        public MaterialProperty _ALUVWidth = null;

        //Experimenting
        public MaterialProperty _DissolveBlendPower = null;
        public MaterialProperty _DissolveLayer1Scale = null;
        public MaterialProperty _DissolveLayer2Scale = null;
        public MaterialProperty _DissolveLayer1Speed = null;
        public MaterialProperty _DissolveLayer2Speed = null;
        public MaterialProperty _ClipMask = null;
        public MaterialProperty _ClipIndex = null;
        public MaterialProperty _ClipSlider00 = null;
        public MaterialProperty _ClipSlider01 = null;
        public MaterialProperty _ClipSlider02 = null;
        public MaterialProperty _ClipSlider03 = null;
        public MaterialProperty _ClipSlider04 = null;
        public MaterialProperty _ClipSlider05 = null;
        public MaterialProperty _ClipSlider06 = null;
        public MaterialProperty _ClipSlider07 = null;
        public MaterialProperty _ClipSlider08 = null;
        public MaterialProperty _ClipSlider09 = null;
        public MaterialProperty _ClipSlider10 = null;
        public MaterialProperty _ClipSlider11 = null;
        public MaterialProperty _ClipSlider12 = null;
        public MaterialProperty _ClipSlider13 = null;
        public MaterialProperty _ClipSlider14 = null;
        public MaterialProperty _ClipSlider15 = null;

        //Material Properties for Eye tracking Plugins
        public MaterialProperty _LeftRightPan = null;
        public MaterialProperty _UpDownPan = null;
        public MaterialProperty _Twitchyness = null;
        public MaterialProperty _AttentionSpan = null;
        public MaterialProperty _FollowPower = null;
        public MaterialProperty _FollowLimit = null;
        public MaterialProperty _LookSpeed = null;
        public MaterialProperty _IrisSize = null;
        public MaterialProperty _EyeOffsetLimit = null;
        //--

        //Properties for Fur plugin
        public MaterialProperty _FurTexture = null;
        public MaterialProperty _FurLengthMask = null;
        public MaterialProperty _NoiseTexture = null;
        public MaterialProperty _LayerCount = null;
        public MaterialProperty _FurLength = null;
        public MaterialProperty _FurWidth = null;
        public MaterialProperty _Gravity = null;
        public MaterialProperty _CombX = null;
        public MaterialProperty _CombY = null;
        public MaterialProperty _FurOcclusion = null;
        public MaterialProperty _OcclusionFalloffMin = null;
        public MaterialProperty _OcclusionFalloffMax = null;
        public MaterialProperty _ColorFalloffMin = null;
        public MaterialProperty _ColorFalloffMax = null;
        public MaterialProperty _BottomColor = null;
        public MaterialProperty _TopColor = null;
        public MaterialProperty _StrandAmount = null;
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