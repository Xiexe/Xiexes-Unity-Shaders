v2f vert (appdata v)
{
	v2f o;
	
	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	float3 wnormal = mul(unity_ObjectToWorld, v.normal);
	float3 tangent = mul(unity_ObjectToWorld, v.tangent);
	float3 bitangent = cross(tangent, wnormal);
	o.ntb[0] = wnormal;
	o.ntb[1] = tangent;
	o.ntb[2] = bitangent;
	o.uv = v.uv;
	o.uv1 = v.uv1;
	
	TRANSFER_SHADOW(o);
	return o;
}

float4 frag (v2f i) : SV_Target
{
	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
	TextureUV t = (TextureUV)0; // Populate UVs
	InitializeTextureUVs(i, t);
	
	XSLighting o = (XSLighting)0; //Populate Lighting Struct
	o.albedo = tex2D(_MainTex, t.albedoUV) * _Color;
	o.specularMap = tex2D(_SpecularMap, t.specularMapUV);
	o.metallicGlossMap = tex2D(_MetallicGlossMap, t.metallicGlossMapUV);
	o.detailMask = tex2D(_DetailMask, t.detailMaskUV);
	o.normalMap = tex2D(_BumpMap, t.normalMapUV);
	o.detailNormal = tex2D(_DetailNormalMap, t.detailNormalUV);

	o.attenuation = attenuation;
	o.normal = i.ntb[0];
	o.tangent = i.ntb[1];
	o.bitangent = i.ntb[2];
	o.worldPos = i.worldPos;
	
	float4 col = XSLighting_BRDF_Toon(o);
	calcAlpha(o);
	return float4(col.rgb, o.alpha);
}