#define TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o,opos,vertex,normal) \
opos = UnityClipSpaceShadowCasterPos(vertex, normal); \
opos = UnityApplyLinearShadowBias(opos);

//----


#if defined(_FUR_SHELL)
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
#endif

#if defined(_FUR_FIN)
float rand(float3 co)
{
    return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}

// Construct a rotation matrix that rotates around the provided axis, sourced from:
// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
float3x3 AngleAxis3x3(float angle, float3 axis)
{
    float c, s;
    sincos(angle, s, c);

    float t = 1 - c;
    float x = axis.x;
    float y = axis.y;
    float z = axis.z;

    return float3x3(
        t * x * x + c, t * x * y - s * z, t * x * z + s * y,
        t * x * y + s * z, t * y * y + c, t * y * z - s * x,
        t * x * z - s * y, t * y * z + s * x, t * z * z + c
        );
}

float3x3 rotX(float angle)
{
    float s, c;
    sincos(angle, s, c);

    return float3x3(
            1, 0, 0,
            0, c, -s,
            0, s, c
        );
}

float3x3 rotZ(float angle)
{
    float s, c;
    sincos(angle, s, c);

    return float3x3(
            c, -s, 0,
            s, c, 0,
            0, 0, 1
        );
}

float3x3 tangentToLocal(float3 normal, float4 tangent, float3 bitangent)
{
    float3x3 t2l = float3x3(
        tangent.x, bitangent.x, normal.x,
        tangent.y, bitangent.y, normal.y,
        tangent.z, bitangent.z, normal.z
    );

    return t2l;
}

g2f GenerateVertex(triangle v2g IN[3], float3 vPos, float2 uv, float width, float height, float forward, float3 normal, float3 tangent, float3 bitangent, float3x3 transformMatrix)
{
    float3 tangentPoint = float3(width, forward, height);
    vPos = vPos + mul(transformMatrix, tangentPoint);

    g2f o = (g2f)0;
    o.pos = UnityObjectToClipPos(vPos);
    o.uv = uv;
    o.layer = 1;
    //Only pass needed things through for shadow caster
    #if !defined(UNITY_PASS_SHADOWCASTER)
    o.worldPos = mul(unity_ObjectToWorld, float4(vPos, 1));
    o.ntb[0] = normal;
    o.ntb[1] = tangent;
    o.ntb[2] = bitangent;
    o.uv1 = IN[0].uv1;
    o.uv2 = IN[0].uv2;
    o.color = float4(IN[0].color.rgb, 0); // store if outline in alpha channel of vertex colors | 1 = is an outline
    o.screenPos = ComputeScreenPos(o.pos);
    o.objPos = normalize(vPos);
    #elif defined(UNITY_PASS_SHADOWCASTER)
    TRANSFER_SHADOW_CASTER_NOPOS_GEOMETRY(o, o.pos, vPos, normal);
    #endif
    return o;
}

[maxvertexcount(6)]
[instance(32)]
void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream, uint instanceID : SV_GSInstanceID)
{
    g2f o = (g2f)0;

    UNITY_SETUP_INSTANCE_ID(IN[0]);
    UNITY_INITIALIZE_OUTPUT(g2f, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    UNITY_TRANSFER_INSTANCE_ID(IN[0], o);
    int currentLayer = instanceID;

    if(currentLayer == 0) // Skin
    {
        for (int i = 0; i < 3; i++)
        {
            float3 worldNormal = IN[i].ntb[0];
            float4 worldPos = IN[i].worldPos;
            float4 vertexPos = worldPos;

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
            o.layer = 0;

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
    else // Fur
    {
        float3 vPos = IN[0].vertex;
        vPos = lerp(vPos, IN[1].vertex, rand(vPos * currentLayer));
        vPos = lerp(vPos, IN[2].vertex, rand(vPos * currentLayer));
        
        float3 vNormal = IN[0].ntb[0];
        vNormal = lerp(vNormal, IN[1].ntb[0], rand(vPos * currentLayer));
        vNormal = lerp(vNormal, IN[2].ntb[0], rand(vPos * currentLayer));

        float4 vTangent = float4(IN[0].ntb[1], 1);
        vTangent.xyz = lerp(vTangent, IN[1].ntb[1], rand(vPos * currentLayer));
        vTangent.xyz = lerp(vTangent, IN[2].ntb[1], rand(vPos * currentLayer));

        float3 vBitangent = cross(vNormal, vTangent);

        float3x3 tan2local = tangentToLocal(vNormal, vTangent, vBitangent);
        float3x3 randomRot = rotZ(rand(vPos) * UNITY_TWO_PI);
        float3x3 bendRot = rotX(rand(vPos.zzx) * _FurMessiness * UNITY_PI * 0.5);
        
        float3x3 transformationMatrix; 
        transformationMatrix = mul(tan2local, randomRot); // apply random rotation
        transformationMatrix = mul( transformationMatrix, bendRot); // apply bend
        
        float height = max(0.01, rand(vPos.zzy) * _FurLengthRandomness + _FurLength);
        float width = max(0.01, rand(vPos.xzy) * _FurWidthRandomness + _FurWidth);
        float forward = 0;

        tristream.Append(GenerateVertex(IN, vPos, float2(0,0), width, 0, forward, vNormal, vTangent, vBitangent, transformationMatrix));
        tristream.Append(GenerateVertex(IN, vPos, float2(1,0), -width, 0, forward, vNormal, vTangent, vBitangent, transformationMatrix));
        tristream.Append(GenerateVertex(IN, vPos, float2(0,1), width, height, forward, vNormal, vTangent, vBitangent, transformationMatrix));
        tristream.Append(GenerateVertex(IN, vPos, float2(1,1), -width, height, forward, vNormal, vTangent, vBitangent, transformationMatrix));
    }
}
#endif
