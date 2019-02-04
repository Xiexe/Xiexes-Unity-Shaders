v2f vert (appdata v)
{
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	
	float3 wnormal = mul(unity_ObjectToWorld, v.normal);
	float3 tangent = mul(unity_ObjectToWorld, v.tangent);
	float3 bitangent = cross(tangent, wnormal);

	o.ntb[0] = wnormal; // Normal in world space
	o.ntb[1] = tangent;
	o.ntb[2] = bitangent;

	TRANSFER_SHADOW(o);
	return o;
}

float4 frag (v2f i) : SV_Target
{
	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
	
	XSLighting o = (XSLighting)0; //Populate Lighting Struct
	o.albedo = tex2D(_MainTex, i.uv);
	o.specularMap = tex2D(_SpecularMap, i.uv);
	o.metallicGlossMap = tex2D(_MetallicGlossMap, i.uv);
	o.detailMask = tex2D(_DetailMask, i.uv);
	o.normalMap = tex2D(_BumpMap, i.uv);

	o.attenuation = attenuation;
	o.normal = i.ntb[0];
	o.tangent = i.ntb[1];
	o.bitangent = i.ntb[2];
	o.worldPos = i.worldPos;
	o.worldNormal = calcNormal(o);
	
	float4 light = lighting(o);
	return light;
}