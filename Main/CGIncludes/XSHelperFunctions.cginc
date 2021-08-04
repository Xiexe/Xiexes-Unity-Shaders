void calcNormal(inout FragmentData i)
{
    if(_NormalMapMode == 0)
    {
        half3 nMap = UnpackScaleNormal(i.normalMap, _BumpScale);
        half3 detNMap = UnpackScaleNormal(i.detailNormal, _DetailNormalMapScale);

        half3 blendedNormal = lerp(nMap, BlendNormals(nMap, detNMap), i.detailMask.r);
        half3 calcedNormal = normalize(blendedNormal.x * i.tangent + blendedNormal.y * i.bitangent + blendedNormal.z * i.normal);

        half3 bumpedTangent = cross(i.bitangent, calcedNormal);
        half3 bumpedBitangent = cross(calcedNormal, bumpedTangent);

        i.normal = calcedNormal;
        i.tangent = bumpedTangent;
        i.bitangent = bumpedBitangent;
    }
    else
    {
        float3 vcol = i.color.rgb * 2 - 1;
        half3 calcedNormal = normalize(vcol.x * i.tangent + vcol.y * i.bitangent + vcol.z * i.normal);;

        //calcedNormal = calcedNormal;
        i.normal = normalize(calcedNormal);
    }
}

void InitializeTextureUVs(
    #if defined(Geometry)
        in g2f i,
    #else
        in VertexOutput i,
    #endif
        inout TextureUV t)
{
    #if defined(PatreonEyeTracking)
        float2 eyeUvOffset = eyeOffsets(i.uv, i.objPos, i.worldPos, i.ntb[0]);
        i.uv = eyeUvOffset;
        i.uv1 = eyeUvOffset;
    #endif

    t.uv0 = i.uv;
    t.uv1 = i.uv1;
    t.uv2 = i.uv2;

    half2 uvSetAlbedo = (_UVSetAlbedo == 0) ? i.uv : i.uv1;
    t.albedoUV = TRANSFORM_TEX(uvSetAlbedo, _MainTex);

    half2 uvSetClipMap = (_UVSetClipMap == 0) ? i.uv : i.uv1;
    t.clipMapUV = TRANSFORM_TEX(uvSetClipMap, _ClipMap);

    half2 uvSetDissolveMap = (_UVSetDissolve == 0) ? i.uv : i.uv1;
    t.dissolveUV = TRANSFORM_TEX(uvSetDissolveMap, _DissolveTexture);

    #if !defined(UNITY_PASS_SHADOWCASTER)
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

        half2 uvSetSpecularMap = (_UVSetSpecular == 0) ? i.uv : i.uv1;
        t.specularMapUV = TRANSFORM_TEX(uvSetSpecularMap, _SpecularMap);

        half2 uvSetThickness = (_UVSetThickness == 0) ? i.uv : i.uv1;
        t.thicknessMapUV = TRANSFORM_TEX(uvSetThickness, _ThicknessMap);

        half2 uvSetReflectivityMask = (_UVSetReflectivity == 0) ? i.uv : i.uv1;
        t.reflectivityMaskUV = TRANSFORM_TEX(uvSetReflectivityMask, _ReflectivityMask);

        half2 uvSetRimMask = (_UVSetRimMask == 0) ? i.uv : i.uv1;
        t.rimMaskUV = TRANSFORM_TEX(uvSetReflectivityMask, _RimMask);
    #endif
}

float Remap_Float(float In, float2 InMinMax, float2 OutMinMax)
{
    return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
}

half3 rgb2hsv(half3 c)
{
    half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    half4 p = lerp(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
    half4 q = lerp(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return half3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

half3 hsv2rgb(half3 c)
{
    half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    half3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void InitializeTextureUVsMerged(
    #if defined(Geometry)
        in g2f i,
    #else
        in VertexOutput i,
    #endif
        inout TextureUV t)
{
    t.uv0 = i.uv;
    t.uv1 = i.uv1;
    t.uv2 = i.uv2;

    half2 uvSetAlbedo = (_UVSetAlbedo == 0) ? i.uv : i.uv1;
    t.albedoUV = TRANSFORM_TEX(uvSetAlbedo, _MainTex);
    t.normalMapUV = t.albedoUV;
    t.emissionMapUV = t.albedoUV;
    t.metallicGlossMapUV = t.albedoUV;
    t.occlusionUV = t.albedoUV;
    t.detailNormalUV = t.albedoUV;
    t.detailMaskUV = t.albedoUV;
    t.specularMapUV = t.albedoUV;
    t.thicknessMapUV = t.albedoUV;
    t.reflectivityMaskUV = t.albedoUV;
    t.clipMapUV = t.albedoUV;

    //Dissolve map makes sense to be on a sep. UV always.
    half2 uvSetDissolveMap = (_UVSetDissolve == 0) ? i.uv : i.uv1;
    t.dissolveUV = TRANSFORM_TEX(uvSetDissolveMap, _DissolveTexture);
}

bool IsInMirror()
{
    return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

inline half Dither8x8Bayer( int x, int y )
{
    const half dither[ 64 ] = {
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

half2 calcScreenUVs(half4 screenPos)
{
    half2 uv = screenPos / (screenPos.w + 0.0000000001); //0.0x1 Stops division by 0 warning in console.
    #if UNITY_SINGLE_PASS_STEREO
        uv.xy *= half2(_ScreenParams.x * 2, _ScreenParams.y);
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
        half3 cameraPos = half3((unity_StereoWorldSpaceCameraPos[0]+ unity_StereoWorldSpaceCameraPos[1])*.5);
    #else
        half3 cameraPos = _WorldSpaceCameraPos;
    #endif
        half3 viewDir = cameraPos - worldPos;
    return normalize(viewDir);
}

half2 matcapSample(half3 worldUp, half3 viewDirection, half3 normalDirection)
{
    half3 worldViewUp = normalize(worldUp - viewDirection * dot(viewDirection, worldUp));
    half3 worldViewRight = normalize(cross(viewDirection, worldViewUp));
    half2 matcapUV = half2(dot(worldViewRight, normalDirection), dot(worldViewUp, normalDirection)) * 0.5 + 0.5;
    return matcapUV;
}
                        //Reflection direction, worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
half3 getReflectionUV(half3 direction, half3 position, half4 cubemapPosition, half3 boxMin, half3 boxMax)
{
    #if UNITY_SPECCUBE_BOX_PROJECTION
        if (cubemapPosition.w > 0) {
            half3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
            half scalar = min(min(factors.x, factors.y), factors.z);
            direction = direction * scalar + (position - cubemapPosition);
        }
    #endif
    return direction;
}

half3 getEnvMap(FragmentData i, DotProducts d, float blur, half3 reflDir, half3 indirectLight, half3 wnormal)
{//This function handls Unity style reflections, Matcaps, and a baked in fallback cubemap.
    half3 envMap = half3(0,0,0);

    #if defined(UNITY_PASS_FORWARDBASE) //Indirect PBR specular should only happen in the forward base pass. Otherwise each extra light adds another indirect sample, which could mean you're getting too much light.
        half3 reflectionUV1 = getReflectionUV(reflDir, i.worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
        half4 probe0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionUV1, blur);
        half3 probe0sample = DecodeHDR(probe0, unity_SpecCube0_HDR);

        half3 indirectSpecular;
        half interpolator = unity_SpecCube0_BoxMin.w;

        UNITY_BRANCH
        if (interpolator < 0.99999)
        {
            half3 reflectionUV2 = getReflectionUV(reflDir, i.worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
            half4 probe1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, reflectionUV2, blur);
            half3 probe1sample = DecodeHDR(probe1, unity_SpecCube1_HDR);
            indirectSpecular = lerp(probe1sample, probe0sample, interpolator);
        }
        else
        {
            indirectSpecular = probe0sample;
        }

        envMap = indirectSpecular;
    #endif

    return envMap;
}

float AlphaAdjust(float alphaToAdj, float3 vColor)
{
    _ClipAgainstVertexColorGreaterZeroFive = saturate(_ClipAgainstVertexColorGreaterZeroFive); //So the lerp doesn't go crazy
    _ClipAgainstVertexColorLessZeroFive = saturate(_ClipAgainstVertexColorLessZeroFive);

    float modR = vColor.r < 0.5 ? _ClipAgainstVertexColorLessZeroFive.r : _ClipAgainstVertexColorGreaterZeroFive.r;
    float modG = vColor.g < 0.5 ? _ClipAgainstVertexColorLessZeroFive.g : _ClipAgainstVertexColorGreaterZeroFive.g;
    float modB = vColor.b < 0.5 ? _ClipAgainstVertexColorLessZeroFive.b : _ClipAgainstVertexColorGreaterZeroFive.b;

    alphaToAdj *= lerp(0, 1, lerp(1, modR, step(0.01, vColor.r)));
    alphaToAdj *= lerp(0, 1, lerp(1, modG, step(0.01, vColor.g)));
    alphaToAdj *= lerp(0, 1, lerp(1, modB, step(0.01, vColor.b)));

    return alphaToAdj;
}

bool IsColorMatch(float3 color1, float3 color2)
{
    float epsilon = 0.1;
    float3 delta = abs(color1.rgb - color2.rgb);
    return step((delta.r + delta.g + delta.b), epsilon);
}

float AdjustAlphaUsingTextureArray(FragmentData i, float alphaToAdj)
{
    half4 compValRGBW = 0; // Red Green Blue White
    half4 compValCYMB = 0; // Cyan Yellow Magenta Black
    switch (_ClipIndex) // Each of these is a Vector / 4 masks, 2 per material, so 8 masks per material, 8 materials max, 64 total masks
    {
        case 0 : compValRGBW = _ClipSlider00; compValCYMB = _ClipSlider01; break;
        case 1 : compValRGBW = _ClipSlider02; compValCYMB = _ClipSlider03; break;
        case 2 : compValRGBW = _ClipSlider04; compValCYMB = _ClipSlider05; break;
        case 3 : compValRGBW = _ClipSlider06; compValCYMB = _ClipSlider07; break;
        case 4 : compValRGBW = _ClipSlider08; compValCYMB = _ClipSlider09; break;
        case 5 : compValRGBW = _ClipSlider10; compValCYMB = _ClipSlider11; break;
        case 6 : compValRGBW = _ClipSlider12; compValCYMB = _ClipSlider13; break;
        case 7 : compValRGBW = _ClipSlider14; compValCYMB = _ClipSlider15; break;
    }

    //Compares to Red, Green, Blue, and White against the first slider set
    alphaToAdj *= lerp(1, 1-compValRGBW.r, IsColorMatch(i.clipMap.rgb, float3(1,0,0)));
    alphaToAdj *= lerp(1, 1-compValRGBW.g, IsColorMatch(i.clipMap.rgb, float3(0,1,0)));
    alphaToAdj *= lerp(1, 1-compValRGBW.b, IsColorMatch(i.clipMap.rgb, float3(0,0,1)));
    alphaToAdj *= lerp(1, 1-compValRGBW.w, IsColorMatch(i.clipMap.rgb, float3(1,1,1)));

    //Compares to Cyan, Yellow, Magenta, and Black against the second slider set
    alphaToAdj *= lerp(1, 1-compValCYMB.r, IsColorMatch(i.clipMap.rgb, float3(0,1,1)));
    alphaToAdj *= lerp(1, 1-compValCYMB.g, IsColorMatch(i.clipMap.rgb, float3(1,1,0)));
    alphaToAdj *= lerp(1, 1-compValCYMB.b, IsColorMatch(i.clipMap.rgb, float3(1,0,1)));
    alphaToAdj *= lerp(1, 1-compValCYMB.w, IsColorMatch(i.clipMap.rgb, float3(0,0,0)));

    return alphaToAdj;
}

void calcDissolve(inout FragmentData i, inout float3 col)
{
    #ifdef _ALPHATEST_ON
        float4 mask = i.dissolveMask.x * i.dissolveMaskSecondLayer.x * _DissolveBlendPower;
        half dissolveAmt = Remap_Float(mask, float2(0,1), float2(0.25, 0.75));
        half dissolveProgress = saturate(_DissolveProgress + lerp(0, 1-AdjustAlphaUsingTextureArray(i, 1), _UseClipsForDissolve));
        half dissolve = 0;
        if (_DissolveCoordinates == 0)
        {
            dissolve = dissolveAmt - dissolveProgress;
            clip(dissolve);
        }

        if(_DissolveCoordinates == 1)
        {
            half distToCenter = 1-length(i.objPos);
            dissolve = ((distToCenter + dissolveAmt) * 0.5) - dissolveProgress;
            clip(dissolve);
        }

        if(_DissolveCoordinates == 2)
        {
            half distToCenter = (1-i.objPos.y) * 0.5 + 0.5;
            dissolve = ((distToCenter + dissolveAmt) * 0.5) - dissolveProgress;
            clip(dissolve);
        }

        #if !defined(UNITY_PASS_SHADOWCASTER)
            float4 dissCol = _DissolveColor;
            dissCol.rgb = rgb2hsv(dissCol.rgb);
            dissCol.x += fmod(_Hue, 360);
            dissCol.y = saturate(dissCol.y * _Saturation);
            dissCol.z *= _Value;
            dissCol.rgb = hsv2rgb(dissCol.rgb);

            half dissolveEdge = smoothstep(dissolve, dissolve - (_DissolveStrength * 0.01), dissolve * dissolveAmt);
            dissCol.rgb *= saturate(sin(dissolveProgress * 4) * 3);
            col.rgb += (1-dissolveEdge) * dissCol.rgb;
        #endif
    #endif
}

//todo: What the fuck is going on here?
void calcAlpha(inout FragmentData i, TextureUV t, inout float alpha)
{
    #if !defined(Fur)
        #if defined(_ALPHABLEND_ON) && !defined(_ALPHATEST_ON) // Traditional Alphablended / Fade blending
            alpha = i.albedo.a;

            #ifdef UNITY_PASS_SHADOWCASTER
                half dither = calcDither(i.screenUV.xy);
                clip(alpha - dither);
            #endif
        #endif

        #if !defined(_ALPHABLEND_ON) && defined(_ALPHATEST_ON) // Dithered / Cutout transparency
            float modifiedAlpha = lerp(AdjustAlphaUsingTextureArray(i, i.albedo.a), i.albedo.a, _UseClipsForDissolve);
            if(_BlendMode == 2)
            {
                half dither = calcDither(i.screenUV.xy);
                float fadeDist = abs(_FadeDitherDistance);
                float d = distance(_WorldSpaceCameraPos, i.worldPos);
                d = smoothstep(fadeDist, fadeDist + 0.05, d);
                d = lerp(d, 1-d, saturate(step(0, _FadeDitherDistance)));
                dither += lerp(0, d, saturate(_FadeDither));
                clip(modifiedAlpha - dither);
            }

            if(_BlendMode == 1)
            {
                clip(modifiedAlpha - _Cutoff);
            }
        #endif

        #if defined(_ALPHABLEND_ON) && defined(_ALPHATEST_ON) // Alpha to Coverage
            float modifiedAlpha = lerp(AdjustAlphaUsingTextureArray(i, i.albedo.a), i.albedo.a, _UseClipsForDissolve);
            half dither = calcDither(i.screenUV.xy);
            alpha = modifiedAlpha - (dither * (1-i.albedo.a) * 0.15);
            #if defined(UNITY_PASS_SHADOWCASTER)
                clip(modifiedAlpha - dither);
            #endif
        #endif
    #endif
}

float lerpstep(float a, float b, float t)
{
    return saturate( ( t - a ) / ( b - a ) );
}

// //Halftone functions, finish implementing later.. Not correct right now.
float2 SphereUV( float3 coords /*viewDir?*/)
{
    float3 nc = normalize(coords);
    float lat = acos(nc.y);
    float lon = atan2(nc.z, nc.x);
    float2 coord = 1.0 - (float2(lon, lat) * float2(1.0/UNITY_PI, 1.0/UNITY_PI));
    return (coord + float4(0, 1-unity_StereoEyeIndex,1,1.0).xy) * float4(0, 1-unity_StereoEyeIndex,1,1.0).zw;
}

half2 rotateUV(half2 uv, half rotation)
{
    half mid = 0.5;
    return half2(
        cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
        cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

half DotHalftone(FragmentData i, half scalar) //Scalar can be anything from attenuation to a dot product
{
	bool inMirror = IsInMirror();
	half2 uv = SphereUV(calcViewDir(i.worldPos));
    uv.xy *= _HalftoneDotAmount;
    half2 nearest = 2 * frac(100 * uv) - 1;
    half dist = length(nearest);
	half dotSize = 100 * _HalftoneDotSize * scalar;
    half dotMask = step(dotSize, dist);

	return lerp(1, 1-dotMask, smoothstep(0, 0.4, 1/distance(i.worldPos, _WorldSpaceCameraPos)));;
}

half LineHalftone(FragmentData i, half scalar)
{
	// #if defined(DIRECTIONAL)
	// 	scalar = saturate(scalar + ((1-i.attenuation) * 0.2));
	// #endif
	bool inMirror = IsInMirror();
	half2 uv = SphereUV(calcViewDir(i.worldPos));
	uv = rotateUV(uv, -0.785398);
	uv.x = sin(uv.x * _HalftoneLineAmount * scalar);

	half2 steppedUV = smoothstep(0,0.2,uv.x);
	half lineMask = lerp(1, steppedUV, smoothstep(0, 0.4, 1/distance(i.worldPos, _WorldSpaceCameraPos)));

	return saturate(lineMask);
}

float flength(float i) { return length(float2(ddx(i), ddy(i))); }
//