void calcNormal(inout XSLighting i)
{
	half3 nMap = UnpackNormal(i.normalMap);
	nMap.xy *= _BumpScale;
	half3 calcedNormal = half3( i.bitangent * nMap.r + 
								i.tangent * nMap.g +
								i.normal * nMap.b  );

	calcedNormal = normalize(calcedNormal);
	half3 bumpedTangent = (cross(i.bitangent, calcedNormal));
    half3 bumpedBitangent = (cross(calcedNormal, bumpedTangent));
	
	i.normal = calcedNormal;
	i.tangent = bumpedTangent;
	i.bitangent = bumpedBitangent;
}

void InitializeTextureUVs(
	#if defined(Geometry)
		in g2f i,
	#else
		in VertexOutput i, 
	#endif
		inout TextureUV t)
{	
	half2 uvSetAlbedo = (_UVSetAlbedo == 0) ? i.uv : i.uv1;
	half2 uvSetNormalMap = (_UVSetNormal == 0) ? i.uv : i.uv1;
	half2 uvSetDetailNormal = (_UVSetDetNormal == 0) ? i.uv : i.uv1;
	half2 uvSetDetailMask = (_UVSetDetMask == 0) ? i.uv : i.uv1;
	half2 uvSetMetallicGlossMap = (_UVSetMetallic == 0) ? i.uv : i.uv1;
	half2 uvSetSpecularMap = (_UVSetSpecular == 0) ? i.uv : i.uv1;
	half2 uvSetThickness = (_UVSetThickness == 0) ? i.uv : i.uv1;
	half2 uvSetOcclusion = (_UVSetOcclusion == 0) ? i.uv : i.uv1;
	half2 uvSetReflectivityMask = (_UVSetReflectivity == 0) ? i.uv : i.uv1;
	half2 uvSetEmissionMap = (_UVSetEmission == 0) ? i.uv : i.uv1;

	t.albedoUV = TRANSFORM_TEX(uvSetAlbedo, _MainTex);
	t.normalMapUV = TRANSFORM_TEX(uvSetNormalMap, _BumpMap);
	t.detailNormalUV = TRANSFORM_TEX(uvSetDetailNormal, _DetailNormalMap);
	t.detailMaskUV = TRANSFORM_TEX(uvSetDetailMask, _DetailMask);
	t.metallicGlossMapUV = TRANSFORM_TEX(uvSetMetallicGlossMap, _MetallicGlossMap);
	t.specularMapUV = TRANSFORM_TEX(uvSetSpecularMap, _SpecularMap);
	t.thicknessMapUV = TRANSFORM_TEX(uvSetSpecularMap, _ThicknessMap);
	t.occlusionUV = TRANSFORM_TEX(uvSetSpecularMap, _OcclusionMap);
	t.reflectivityMaskUV = TRANSFORM_TEX(uvSetReflectivityMask, _ReflectivityMask);
	t.emissionMapUV = TRANSFORM_TEX(uvSetEmissionMap, _EmissionMap);
}


half3 calcViewDir(half3 worldPos)
{
	half3 viewDir = _WorldSpaceCameraPos - worldPos;
	return normalize(viewDir);
}

half3 calcStereoViewDir(half3 worldPos)
{
	#if UNITY_SINGLE_PASS_STEREO
		float3 cameraPos = float3((unity_StereoWorldSpaceCameraPos[0]+ unity_StereoWorldSpaceCameraPos[1])*.5); 
	#else
		float3 cameraPos = _WorldSpaceCameraPos;
	#endif
		float3 viewDir = cameraPos - worldPos;
	return normalize(viewDir);
}

float2 matcapSample(float3 worldUp, float3 viewDirection, float3 normalDirection)
{
	half3 worldViewUp = normalize(worldUp - viewDirection * dot(viewDirection, worldUp));
	half3 worldViewRight = normalize(cross(viewDirection, worldViewUp));
	half2 matcapUV = half2(dot(worldViewRight, normalDirection), dot(worldViewUp, normalDirection)) * 0.5 + 0.5;
	return matcapUV;				
}
						//Reflection direction, worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
float3 getReflectionUV(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax) 
{
	#if UNITY_SPECCUBE_BOX_PROJECTION
		if (cubemapPosition.w > 0) {
			float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - cubemapPosition);
		}
	#endif
	return direction;
}

void calcAlpha(inout XSLighting i)
{	
	//Default to 1 alpha || Opaque
	i.alpha = 1;

	#if defined(AlphaBlend) || defined(AlphaToMask)
		i.alpha = i.albedo.a;
	#endif

	#if defined(Cutout)
		clip(i.albedo.a - _Cutoff);
	#endif
}




// Halftone functions, finish implementing later.. Not correct right now.
// //Half tone functions
// float2 calcScreenUVs(float4 screenPos, float distanceToObjectOrigin)
// {
// 	float2 clipPos = screenPos / (screenPos.w + 0.0000000001);
// 	float2 uv = 2*clipPos-1;

// 	#if UNITY_SINGLE_PASS_STEREO
// 		uv.x *= (_ScreenParams.x * 2) / _ScreenParams.y;
// 	#else
// 		uv.x *= (_ScreenParams.x) / _ScreenParams.y;
// 	#endif
// 	uv *= distanceToObjectOrigin;
// 	return uv;
// }

// float2 rotateUV(float2 uv, float rotation)
// {
//     float mid = 0.5;
//     return float2(
//         cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
//         cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
//     );
// }

// bool IsInMirror()
// {
//     return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
// }

// float DotHalftone(XSLighting i, float scalar) //Scalar can be anything from attenuation to a dot product
// {
// 	bool inMirror = IsInMirror();
// 	float2 uv = i.screenUV;
// 	#if UNITY_SINGLE_PASS_STEREO
// 		uv *= 2;
// 	#endif
	
//     float2 nearest = 2 * frac(_HalftoneDotAmount * uv) - 1;
//     float dist = length(nearest);
// 	float dotSize = _HalftoneDotSize * scalar;
//     float dotMask = step(dotSize, dist);

// 	return dotMask;
// }

// float LineHalftone(XSLighting i, float scalar)
// {	
// 	// #if defined(DIRECTIONAL)
// 	// 	scalar = saturate(scalar + ((1-i.attenuation) * 0.2));
// 	// #endif
// 	bool inMirror = IsInMirror();
// 	float2 uv = i.screenUV;
// 	uv = rotateUV(uv, -0.785398);
// 	#if UNITY_SINGLE_PASS_STEREO
// 		_HalftoneLineAmount = _HalftoneLineAmount * 2;

// 	#endif
// 	uv.x = sin(uv.x * _HalftoneLineAmount);

// 	float2 steppedUV = smoothstep(0,0.2,uv.x);
// 	float lineMask = steppedUV * 0.2 * scalar;

// 	return saturate(lineMask);
// }
// //