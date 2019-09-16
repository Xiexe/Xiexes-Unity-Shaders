float4 frag (
    #if defined(Geometry)
        g2f i
    #else
        VertexOutput i
    #endif
    , uint facing : SV_IsFrontFace
    ) : SV_Target
{
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
    #if defined(DIRECTIONAL)
        attenuation = lerp(attenuation, round(attenuation), _ShadowSharpness);
    #endif
    
    bool face = facing > 0; // True if on front face, False if on back face

    if (!face) // Invert Normals based on face
    { 
        if(i.color.a > 0.99) { discard; }//Discard outlines front face always. This way cull off and outlines can be enabled.

        i.ntb[0] = -i.ntb[0];
        i.ntb[1] = -i.ntb[1];
        i.ntb[2] = -i.ntb[2];
    }

    TextureUV t = (TextureUV)0; // Populate UVs
    if(_TilingMode != 1)
    {
        InitializeTextureUVs(i, t);
    }
    else
    {
        InitializeTextureUVsMerged(i, t);
    }

    XSLighting o = (XSLighting)0; //Populate Lighting Struct
    o.albedo = UNITY_SAMPLE_TEX2D(_MainTex, t.albedoUV) * _Color * lerp(1, float4(i.color.rgb, 1), _VertexColorAlbedo);
    o.specularMap = UNITY_SAMPLE_TEX2D_SAMPLER(_SpecularMap, _MainTex, t.specularMapUV);
    o.metallicGlossMap = UNITY_SAMPLE_TEX2D_SAMPLER(_MetallicGlossMap, _MainTex, t.metallicGlossMapUV);
    o.detailMask = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailMask, _MainTex, t.detailMaskUV);
    o.normalMap = UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, t.normalMapUV);
    o.detailNormal = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailNormalMap, _MainTex, t.detailNormalUV);
    o.thickness = UNITY_SAMPLE_TEX2D_SAMPLER(_ThicknessMap, _MainTex, t.thicknessMapUV);
    o.occlusion = tex2D(_OcclusionMap, t.occlusionUV);
    o.reflectivityMask = UNITY_SAMPLE_TEX2D_SAMPLER(_ReflectivityMask, _MainTex, t.reflectivityMaskUV) * _Reflectivity;
    o.emissionMap = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, t.emissionMapUV) * _EmissionColor;
    o.rampMask = UNITY_SAMPLE_TEX2D_SAMPLER(_RampSelectionMask, _MainTex, i.uv); // This texture doesn't need to ever be on a second uv channel, and doesn't need tiling, convince me otherwise.

    o.diffuseColor = o.albedo.rgb; //Store this to separate the texture color and diffuse color for later.
    o.attenuation = attenuation;
    o.normal = i.ntb[0];
    o.tangent = i.ntb[1];
    o.bitangent = i.ntb[2];
    o.worldPos = i.worldPos;
    o.color = i.color.rgb;
    o.isOutline = i.color.a;
    o.screenUV = calcScreenUVs(i.screenPos);
    o.objPos = i.objPos;

    float4 col = BRDF_XSLighting(o);
    calcAlpha(o);
    UNITY_APPLY_FOG(i.fogCoord, col);
    return float4(col.rgb, o.alpha);
}