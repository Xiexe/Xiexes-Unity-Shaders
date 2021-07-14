#if defined(Geometry)
    #define TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o, opos, vertexPosition, vertexNormal) \
        opos = UnityClipSpaceShadowCasterPos(vertexPosition, vertexNormal); \
        opos = UnityApplyLinearShadowBias(opos);

    int _MeshVertexCount;
    float _MeshScale;
    Texture2D<half4> _VertexPosUVXTexture;
    Texture2D<half4> _VertexNormalUVYTexture;
    Texture2D<half4> _VertexColorTexture;

    #define k_MAXVERTEXCOUNT 16
    [maxvertexcount(k_MAXVERTEXCOUNT)]
    [instance(32)]
    void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream, uint primitiveID : SV_PrimitiveID, uint instanceID : SV_GSInstanceID)
    {
        g2f o = (g2f)0;

        UNITY_SETUP_INSTANCE_ID(IN[0]);
        UNITY_INITIALIZE_OUTPUT(g2f, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        UNITY_TRANSFER_INSTANCE_ID(IN[0], o);

        float offset = (k_MAXVERTEXCOUNT / 3);
        uint startTri = instanceID * offset;
        float4 centerPos = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;

        for (int k = startTri; k <= floor(_MeshVertexCount) && k < (startTri + offset); k++)
        {
            for (int i = 0; i < 3; i++)
            {
                float4 vertexPos = _VertexPosUVXTexture.Load(int3(k*3 + i, 0, 0)) ;
                vertexPos.xyz *= _MeshScale;
                vertexPos.xyz += centerPos;
                vertexPos.y += 0.05f;

                float4 vertexNormal = _VertexNormalUVYTexture.Load(int3(k*3 + i, 0, 0));
                float4 vertexColor = _VertexColorTexture.Load(int3(k*3 + i, 0, 0));

                float4 vertexPosition = float4(vertexPos.xyz, 1);
                o.pos = UnityObjectToClipPos(vertexPosition);
                o.worldPos = mul(unity_ObjectToWorld, vertexPosition);
                o.ntb[0] = UnityObjectToWorldNormal(vertexNormal.xyz);
                o.ntb[1] = IN[i].ntb[1];
                o.ntb[2] = IN[i].ntb[2];
                o.uv.xy = float2(vertexPos.w, vertexNormal.w);
                o.color = float4(IN[i].color.rgb,0); // store if outline in alpha channel of vertex colors | 0 = not an outline
                o.screenPos = ComputeScreenPos(o.pos);
                o.objPos = normalize(IN[i].vertex);

                #if !defined(UNITY_PASS_SHADOWCASTER)
                UNITY_TRANSFER_SHADOW(o, o.uv);
                UNITY_TRANSFER_FOG(o, o.pos);
                #else
                TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o, o.pos, IN[i].vertex, IN[i].ntb[0]);
                #endif
                tristream.Append(o);
            }
            tristream.RestartStrip();
        }
    }
#endif