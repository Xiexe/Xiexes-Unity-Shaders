VertexOutput vert (VertexInput v)
{
	VertexOutput o;
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
	o.color = float4(1,1,1,0); // store if outline in alpha channel of vertex colors
	o.normal = v.normal;
	o.screenPos = ComputeScreenPos(o.pos);
	//o.distanceToOrigin = distance( _WorldSpaceCameraPos, mul(unity_ObjectToWorld, float4(0,0,0,1) ));
	TRANSFER_SHADOW(o);
	return o;
}

#if defined(Geometry)
	[maxvertexcount(6)]
	void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream)
	{
		g2f o;

		for (int i = 2; i >= 0; i--)
		{	
			float4 worldPos = (mul(unity_ObjectToWorld, IN[i].vertex));
			float3 outlineWidth = (_OutlineWidth) * .01;
			outlineWidth *= min(distance(worldPos, _WorldSpaceCameraPos) * 3, 1);
			float4 outlinePos = float4(IN[i].vertex + normalize(IN[i].normal) * outlineWidth, 1);
			
			o.pos = UnityObjectToClipPos(outlinePos);
			o.worldPos = worldPos;
			o.ntb[0] = IN[i].ntb[0];
			o.ntb[1] = IN[i].ntb[1];
			o.ntb[2] = IN[i].ntb[2];
			o.uv = IN[i].uv;
			o.uv1 = IN[i].uv1;
			o.color = float4(_OutlineColor.rgb, 1); // store if outline in alpha channel of vertex colors
			o.screenPos = ComputeScreenPos(o.pos);
			//o.distanceToOrigin = IN[i].distanceToOrigin;

			#if defined (SHADOWS_SCREEN) || ( defined (SHADOWS_DEPTH) && defined (SPOT) ) || defined (SHADOWS_CUBE)
				o._ShadowCoord = IN[i]._ShadowCoord; //Can't use TRANSFER_SHADOW() macro here because it expects vertex shader inputs
			#endif

			tristream.Append(o);
		}
		tristream.RestartStrip();
		
		for (int ii = 0; ii < 3; ii++)
		{
			o.pos = UnityObjectToClipPos(IN[ii].vertex);
			o.worldPos = IN[ii].worldPos;
			o.ntb[0] = IN[ii].ntb[0];
			o.ntb[1] = IN[ii].ntb[1];
			o.ntb[2] = IN[ii].ntb[2];
			o.uv = IN[ii].uv;
			o.uv1 = IN[ii].uv1;
			o.color = float4(1,1,1,0); // store if outline in alpha channel of vertex colors
			o.screenPos = ComputeScreenPos(o.pos);
			//o.distanceToOrigin = IN[ii].distanceToOrigin;

			#if defined (SHADOWS_SCREEN) || ( defined (SHADOWS_DEPTH) && defined (SPOT) ) || defined (SHADOWS_CUBE)
				o._ShadowCoord = IN[ii]._ShadowCoord; //Can't use TRANSFER_SHADOW() macro here because it expects vertex shader inputs
			#endif

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
	, float facing : VFACE
	) : SV_Target
{
	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
	#if defined(DIRECTIONAL)
		attenuation = lerp(attenuation, round(attenuation), _ShadowSharpness);
		half nAtten = pow(1-attenuation, 5); // Take 1-Atten as a mask to clean up left over artifacts from self shadowing.
		attenuation = saturate(attenuation + (1-nAtten));
	#endif
	
	bool face = facing > 0; // True if on front face, False if on back face
	face = IsInMirror() ? !face : face; // Faces are inverted in a mirror

	if (!face) // Invert Normals based on face
	{ 
		if(i.color.a > 0.99) { discard; }//Discard outlines front face always. This way cull off and outlines can be enabled.

		i.ntb[0] = -i.ntb[0];
		i.ntb[1] = -i.ntb[1];
		i.ntb[2] = -i.ntb[2];
	}
	//The above handles inverting fixing lighting on back faces and in mirrors.

	TextureUV t = (TextureUV)0; // Populate UVs
	InitializeTextureUVs(i, t);
	
	XSLighting o = (XSLighting)0; //Populate Lighting Struct
	o.albedo = UNITY_SAMPLE_TEX2D(_MainTex, t.albedoUV) * _Color;
	o.specularMap = UNITY_SAMPLE_TEX2D_SAMPLER(_SpecularMap, _MainTex, t.specularMapUV);
	o.metallicGlossMap = UNITY_SAMPLE_TEX2D_SAMPLER(_MetallicGlossMap, _MainTex, t.metallicGlossMapUV);
	o.detailMask = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailMask, _MainTex, t.detailMaskUV);
	o.normalMap = UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, t.normalMapUV);
	o.detailNormal = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailNormalMap, _MainTex, t.detailNormalUV);
	o.thickness = UNITY_SAMPLE_TEX2D_SAMPLER(_ThicknessMap, _MainTex, t.thicknessMapUV);
	o.occlusion = UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap, _MainTex, t.occlusionUV);
	o.reflectivityMask = UNITY_SAMPLE_TEX2D_SAMPLER(_ReflectivityMask, _MainTex, t.reflectivityMaskUV);
	o.emissionMap = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, t.emissionMapUV) * _EmissionColor;

	o.diffuseColor = o.albedo.rgb; //Store this to separate the texture color and diffuse color for later.
	o.attenuation = attenuation;
	o.normal = i.ntb[0];
	o.tangent = i.ntb[1];
	o.bitangent = i.ntb[2];
	o.worldPos = i.worldPos;
	o.color = i.color.rgb;
	o.isOutline = i.color.a;
	o.screenUV = calcScreenUVs(i.screenPos);

	float4 col = XSLighting_BRDF_Toon(o);
	calcAlpha(o);
	return float4(col.rgb, o.alpha);
}