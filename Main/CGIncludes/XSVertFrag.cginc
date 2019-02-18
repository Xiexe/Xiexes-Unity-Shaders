VertexOutput vert (VertexInput v)
{
	VertexOutput o;
	#if defined(Geometry)
		o.pos = v.vertex;
		o.worldPos = v.vertex;
		float3 wnormal = UnityObjectToWorldNormal(v.normal);
		float3 tangent = UnityObjectToWorldDir(v.tangent.xyz);
		float3 bitangent = cross(tangent, wnormal);
		o.ntb[0] = wnormal;
		o.ntb[1] = tangent;
		o.ntb[2] = bitangent;
		o.uv = v.uv;
		o.uv1 = v.uv1;

	#else
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
		TRANSFER_SHADOW(o);

	#endif

	return o;
}

#if defined(Geometry)
	[maxvertexcount(6)]
	void geom(triangle v2g IN[3], inout TriangleStream<VertexOutput> tristream)
	{
		VertexOutput o;
		for (int i = 0; i < 3; i++)
		{
			o.pos = UnityObjectToClipPos(IN[i].pos);
			o.worldPos = mul(unity_ObjectToWorld, IN[i].pos);
			o.ntb[0] = IN[i].ntb[0];
			o.ntb[1] = IN[i].ntb[1];
			o.ntb[2] = IN[i].ntb[2];
			o.uv = IN[i].uv;
			o.uv1 = IN[i].uv1;
		
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
	) : SV_Target
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