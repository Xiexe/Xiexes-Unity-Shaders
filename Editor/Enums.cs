using System;

namespace XSToon3
{
    public class Enums
    {
        [Flags]
        public enum ShaderTypeFlags
        {
            Standard = 0,
            Cutout = 2,
            Dithered = 4,
            AlphaToCoverage = 8,
            Outlined = 16,
            EyeTracking = 32,
            Fur = 64,
        }
        
        public enum AlphaMode
        {
            Opaque,
            Cutout,
            Dithered,
            AlphaToCoverage,
            Transparent,
            Fade,
            Additive
        }
        
        public enum ShaderBlendMode
        {
            Opaque,
            Cutout,
            Fade,
            Transparent
        }

        public enum ReflectionMode
        {
            PBR,
            BakedCube,
            Matcap
        }
    
        public enum NormalMapMode
        {
            Texture,
            VertexColors,
        }
        
        public enum OutlineNormalMode
        {
            MeshNormals,
            VertexColors,
            UVChannel
        }

        public enum HalftoneType
        {
            Shadows,
            Highlights,
            ShadowsAndHighlights,
            NoHalftones
        }

        public enum ShaderMode
        {
            Standard,
            Advanced
        }
    }
}

