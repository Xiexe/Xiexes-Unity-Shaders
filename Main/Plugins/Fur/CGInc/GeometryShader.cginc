#define TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o,opos,vertex,normal) \
opos = UnityClipSpaceShadowCasterPos(vertex, normal); \
opos = UnityApplyLinearShadowBias(opos);

[maxvertexcount(3)]
[instance(32)] // Max layers is 32
void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream, uint instanceID : SV_GSInstanceID)
{
    g2f o = (g2f)0;

    UNITY_SETUP_INSTANCE_ID(IN[0]);
    UNITY_INITIALIZE_OUTPUT(g2f, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    UNITY_TRANSFER_INSTANCE_ID(IN[0], o);

    int currentLayer = instanceID;

    if(currentLayer > _LayerCount)
        return;

    _FurLength = _FurLength * 0.01;
    float3 gravityDir = float4(0,-5,0,0) * _Gravity * _FurLength;
    float layerOffset = (_FurLength * _LayerCount * currentLayer) / _LayerCount;

    for (int i = 0; i < 3; i++)
    {
        float3 worldNormal = IN[i].ntb[0];
        float4 worldPos = IN[i].worldPos;
        float4 vertexPos = float4((worldPos + (normalize(worldNormal) * layerOffset)) + (gravityDir * currentLayer), 1);

        o.pos = UnityWorldToClipPos(vertexPos);
        o.worldPos = worldPos;
        o.ntb[0] = IN[i].ntb[0];
        o.ntb[1] = IN[i].ntb[1];
        o.ntb[2] = IN[i].ntb[2];
        o.uv = IN[i].uv;
        o.uv1 = IN[i].uv1;
        o.uv2 = IN[i].uv2;
        o.color = float4(IN[i].color.rgb, 0); // store if outline in alpha channel of vertex colors | 1 = is an outline
        o.screenPos = ComputeScreenPos(o.pos);
        o.objPos = normalize(vertexPos);
        o.layer = currentLayer;

        #if !defined(UNITY_PASS_SHADOWCASTER)
            UNITY_TRANSFER_SHADOW(o, o.uv);
            UNITY_TRANSFER_FOG(o, o.pos);
        #else
            vertexPos = mul(unity_WorldToObject, vertexPos);
            TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o, o.pos, vertexPos, IN[i].ntb[0]);
        #endif

        tristream.Append(o);
    }
    tristream.RestartStrip();
}