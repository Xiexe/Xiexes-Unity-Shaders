VertexOutput vert (VertexInput v)
{
    VertexOutput o = (VertexOutput)0;
    #if defined(Geometry)
        o.vertex = v.vertex;
    #endif

    o.pos = UnityObjectToClipPos(v.vertex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    float3 wnormal = UnityObjectToWorldNormal(v.normal);
    float3 tangent = UnityObjectToWorldDir(v.tangent.xyz);
    float3 bitangent = cross(tangent, wnormal);
    o.ntb[0] = wnormal;
    o.ntb[1] = tangent;
    o.ntb[2] = bitangent;
    o.uv = v.uv;
    o.uv1 = v.uv1;
    o.color = float4(v.color.rgb, 0); // store if outline in alpha channel of vertex colors | 0 = not an outline
    o.normal = v.normal;
    o.screenPos = ComputeScreenPos(o.pos);
    UNITY_TRANSFER_SHADOW(o, o.uv);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}

#if defined(Geometry)
    [maxvertexcount(6)]
    void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream)
    {
        g2f o;

        //Outlines loop
        for (int i = 2; i >= 0; i--)
        {	
            float4 worldPos = (mul(unity_ObjectToWorld, IN[i].vertex));
            half outlineWidthMask = tex2Dlod(_OutlineMask, float4(IN[i].uv, 0, 0));
            float3 outlineWidth = outlineWidthMask * _OutlineWidth * .01;
            outlineWidth *= min(distance(worldPos, _WorldSpaceCameraPos) * 3, 1);
            float4 outlinePos = float4(IN[i].vertex + normalize(IN[i].normal) * outlineWidth, 1);
            
            o.pos = UnityObjectToClipPos(outlinePos);
            o.worldPos = worldPos;
            o.ntb[0] = IN[i].ntb[0];
            o.ntb[1] = IN[i].ntb[1];
            o.ntb[2] = IN[i].ntb[2];
            o.uv = IN[i].uv;
            o.uv1 = IN[i].uv1;
            o.color = float4(_OutlineColor.rgb, 1); // store if outline in alpha channel of vertex colors | 1 = is an outline
            o.screenPos = ComputeScreenPos(o.pos);

            #if defined (SHADOWS_SCREEN) || ( defined (SHADOWS_DEPTH) && defined (SPOT) ) || defined (SHADOWS_CUBE)
                o._ShadowCoord = IN[i]._ShadowCoord; //Can't use TRANSFER_SHADOW() macro here
            #endif
            UNITY_TRANSFER_FOG(o, o.pos);
            tristream.Append(o);
        }
        tristream.RestartStrip();
        
        //Main Mesh loop
        for (int j = 0; j < 3; j++)
        {
            o.pos = UnityObjectToClipPos(IN[j].vertex);
            o.worldPos = IN[j].worldPos;
            o.ntb[0] = IN[j].ntb[0];
            o.ntb[1] = IN[j].ntb[1];
            o.ntb[2] = IN[j].ntb[2];
            o.uv = IN[j].uv;
            o.uv1 = IN[j].uv1;
            o.color = float4(IN[j].color.rgb,0); // store if outline in alpha channel of vertex colors | 0 = not an outline
            o.screenPos = ComputeScreenPos(o.pos);

            #if defined (SHADOWS_SCREEN) || ( defined (SHADOWS_DEPTH) && defined (SPOT) ) || defined (SHADOWS_CUBE)
                o._ShadowCoord = IN[j]._ShadowCoord; //Can't use TRANSFER_SHADOW() or UNITY_TRANSFER_SHADOW() macros here, could use custom versions of them
            #endif
            UNITY_TRANSFER_FOG(o, o.pos);
            tristream.Append(o);
        }
        tristream.RestartStrip();
    }
#endif

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
    o.albedo = UNITY_SAMPLE_TEX2D(_MainTex, t.albedoUV) * _Color;
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

    float4 col = BRDF_XSLighting(o);
    calcAlpha(o);
    UNITY_APPLY_FOG(i.fogCoord, col);
    return float4(col.rgb, o.alpha);
}