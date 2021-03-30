#if defined(Geometry)
    #define TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o, opos, vertexPosition, vertexNormal) \
        opos = UnityClipSpaceShadowCasterPos(vertexPosition, vertexNormal); \
        opos = UnityApplyLinearShadowBias(opos);

    [maxvertexcount(6)]
    void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream)
    {
        g2f o = (g2f)0;

        UNITY_SETUP_INSTANCE_ID(IN[0]);
        UNITY_INITIALIZE_OUTPUT(g2f, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        UNITY_TRANSFER_INSTANCE_ID(IN[0], o);

        //Main Mesh loop
        for (int i = 0; i < 3; i++)
        {
            o.pos = UnityObjectToClipPos(IN[i].vertex);
            o.worldPos = IN[i].worldPos;
            o.ntb[0] = IN[i].ntb[0];
            o.ntb[1] = IN[i].ntb[1];
            o.ntb[2] = IN[i].ntb[2];
            o.uv = IN[i].uv;
            o.uv1 = IN[i].uv1;
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

        //Outlines loop
        for (int i = 2; i >= 0; i--)
        {
            float4 worldPos = (mul(unity_ObjectToWorld, IN[i].vertex));
            half outlineWidthMask = tex2Dlod(_OutlineMask, float4(IN[i].uv, 0, 0));
            float3 outlineWidth = outlineWidthMask * _OutlineWidth * .01;
            outlineWidth *= min(distance(worldPos, _WorldSpaceCameraPos) * 3, 1);

            float3 vc = IN[i].color.rgb;
            if(_OutlineNormalMode == 2)
            {
                float2 xy = IN[i].uv1;
                if(_OutlineUVSelect == 1)
                    xy = IN[i].uv2;

                float reconstructedZ = sqrt(1-saturate(dot(xy, xy)));
                vc = normalize(float3(xy, reconstructedZ));
            }
            vc = vc * 2 - 1;
            float3 t = mul(unity_WorldToObject, IN[i].ntb[1]);
            float3 b = mul(unity_WorldToObject, IN[i].ntb[2]);
            float3 n = mul(unity_WorldToObject, IN[i].ntb[0]);
            half3 tspace0 = half3(t.x, b.x, n.x);
            half3 tspace1 = half3(t.y, b.y, n.y);
            half3 tspace2 = half3(t.z, b.z, n.z);

            half3 calcedNormal;
            calcedNormal.x = dot(tspace0, vc);
            calcedNormal.y = dot(tspace1, vc);
            calcedNormal.z = dot(tspace2, vc);

            half3 normalDir = normalize(lerp(IN[i].normal, calcedNormal, saturate(_OutlineNormalMode)));
            float4 outlinePos = float4(IN[i].vertex + normalDir * outlineWidth, 1);

            if(outlineWidthMask == 0)
                return;

            o.pos = UnityObjectToClipPos(outlinePos);
            o.worldPos = worldPos;
            o.ntb[0] = IN[i].ntb[0];
            o.ntb[1] = IN[i].ntb[1];
            o.ntb[2] = IN[i].ntb[2];
            o.uv = IN[i].uv;
            o.uv1 = IN[i].uv1;
            o.color = float4(IN[i].color.rgb, 1); // store if outline in alpha channel of vertex colors | 1 = is an outline
            o.screenPos = ComputeScreenPos(o.pos);
            o.objPos = normalize(outlinePos);

            #if !defined(UNITY_PASS_SHADOWCASTER)
                UNITY_TRANSFER_SHADOW(o, o.uv);
                UNITY_TRANSFER_FOG(o, o.pos);
            #else
                TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o, o.pos, outlinePos, IN[i].ntb[0]);
            #endif
            tristream.Append(o);
        }
        tristream.RestartStrip();


    }
#endif