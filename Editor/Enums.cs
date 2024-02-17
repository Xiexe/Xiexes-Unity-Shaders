namespace XSToon3
{
    public class Enums
    {
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
    }
}

