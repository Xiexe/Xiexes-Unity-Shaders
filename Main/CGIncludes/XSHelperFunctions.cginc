void calcNormal(inout XSLighting i)
{
	half3 nMap = UnpackNormal(i.normalMap);
	nMap.xy *= _BumpScale;

	float3 detNMap = UnpackNormal(i.detailNormal);
	detNMap.xy *= _DetailNormalMapScale * i.detailMask.r;

	half3 blendedNormal = half3(nMap.xy*detNMap.z + detNMap.xy*nMap.z, nMap.z*detNMap.z);

	half3 calcedNormal = half3(i.bitangent * blendedNormal.r +
								i.tangent * -blendedNormal.g +
								i.normal * blendedNormal.b);
	
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

	half2 uvSetNormalMap = (_UVSetNormal == 0) ? i.uv : i.uv1;
	t.normalMapUV = TRANSFORM_TEX(uvSetNormalMap, _BumpMap);

	half2 uvSetEmissionMap = (_UVSetEmission == 0) ? i.uv : i.uv1;
	t.emissionMapUV = TRANSFORM_TEX(uvSetEmissionMap, _EmissionMap);

	half2 uvSetMetallicGlossMap = (_UVSetMetallic == 0) ? i.uv : i.uv1;
	t.metallicGlossMapUV = TRANSFORM_TEX(uvSetMetallicGlossMap, _MetallicGlossMap);

	half2 uvSetOcclusion = (_UVSetOcclusion == 0) ? i.uv : i.uv1;
	t.occlusionUV = TRANSFORM_TEX(uvSetOcclusion, _OcclusionMap);

	half2 uvSetDetailNormal = (_UVSetDetNormal == 0) ? i.uv : i.uv1;
	t.detailNormalUV = TRANSFORM_TEX(uvSetDetailNormal, _DetailNormalMap);

	half2 uvSetDetailMask = (_UVSetDetMask == 0) ? i.uv : i.uv1;
	t.detailMaskUV = TRANSFORM_TEX(uvSetDetailMask, _DetailMask);

	half2 uvSetAlbedo = (_UVSetAlbedo == 0) ? i.uv : i.uv1;
	t.albedoUV = TRANSFORM_TEX(uvSetAlbedo, _MainTex);

	half2 uvSetSpecularMap = (_UVSetSpecular == 0) ? i.uv : i.uv1;
	t.specularMapUV = TRANSFORM_TEX(uvSetSpecularMap, _SpecularMap);

	half2 uvSetThickness = (_UVSetThickness == 0) ? i.uv : i.uv1;
	t.thicknessMapUV = TRANSFORM_TEX(uvSetThickness, _ThicknessMap);

	half2 uvSetReflectivityMask = (_UVSetReflectivity == 0) ? i.uv : i.uv1;
	t.reflectivityMaskUV = TRANSFORM_TEX(uvSetReflectivityMask, _ReflectivityMask);	
}

bool IsInMirror()
{
    return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

inline float Dither8x8Bayer( int x, int y )
{
	const float dither[ 64 ] = {
	1, 49, 13, 61,  4, 52, 16, 64,
	33, 17, 45, 29, 36, 20, 48, 32,
	9, 57,  5, 53, 12, 60,  8, 56,
	41, 25, 37, 21, 44, 28, 40, 24,
	3, 51, 15, 63,  2, 50, 14, 62,
	35, 19, 47, 31, 34, 18, 46, 30,
	11, 59,  7, 55, 10, 58,  6, 54,
	43, 27, 39, 23, 42, 26, 38, 22};
	int r = y * 8 + x;
	return dither[r] / 64;
}

half calcDither(half2 screenPos)
{
	half dither = Dither8x8Bayer(fmod(screenPos.x, 8), fmod(screenPos.y, 8));
	return dither;
}

float2 calcScreenUVs(float4 screenPos)
{
	float2 uv = screenPos / (screenPos.w + 0.0000000001); //0.0x1 Stops division by 0 warning in console.
	#if UNITY_SINGLE_PASS_STEREO
		uv.xy *= float2(_ScreenParams.x * 2, _ScreenParams.y);
	#else
		uv.xy *= _ScreenParams.xy;
	#endif
	
	return uv;
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

	#if defined(AlphaBlend)
		i.alpha = i.albedo.a;
	#endif

	#if defined(AlphaToMask) // mix of dithering and alpha blend to provide best results.
		half dither = calcDither(i.screenUV.xy);
		i.alpha = i.albedo.a - (dither * (1-i.albedo.a) * 0.15);//lerp(i.albedo.a, i.albedo.a - (dither * (1-i.albedo.a)), 0.2);
	#endif

	#if defined(Dithered)
		half dither = calcDither(i.screenUV.xy);
		clip(i.albedo.a - dither);
	#endif

	#if defined(Cutout)
		clip(i.albedo.a - _Cutoff);
	#endif
}




// Halftone functions, finish implementing later.. Not correct right now.
// //Half tone functions


// float2 rotateUV(float2 uv, float rotation)
// {
//     float mid = 0.5;
//     return float2(
//         cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
//         cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
//     );
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