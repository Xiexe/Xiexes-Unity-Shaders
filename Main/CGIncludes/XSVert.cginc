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
    half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
    float3 bitangent = cross(wnormal, tangent) * tangentSign;
    o.ntb[0] = wnormal;
    o.ntb[1] = tangent;
    o.ntb[2] = bitangent;
    o.uv = v.uv;
    o.uv1 = v.uv1;
    o.color = float4(v.color.rgb, 0); // store if outline in alpha channel of vertex colors | 0 = not an outline
    o.normal = v.normal;
    o.screenPos = ComputeScreenPos(o.pos);
    o.objPos = normalize(v.vertex);
    UNITY_TRANSFER_SHADOW(o, o.uv);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}