half4 BRDF_XSLighting(HookData data)
{
    FragmentData i = data.i;
    float3 untouchedNormal = data.untouchedNormal;
    TextureUV t = data.t;
    Directions dirs = data.dirs;
    DotProducts d = data.d;

    half3 indirectDiffuse = calcIndirectDiffuse(i);
    bool lightEnv = any(_WorldSpaceLightPos0.xyz);
    half4 metallicSmoothness = calcMetallicSmoothness(i);
    half3 reflViewAniso = getAnisotropicReflectionVector(dirs.viewDir, i.bitangent, i.tangent, i.normal, metallicSmoothness.a, _AnisotropicReflection);

    i.albedo.rgb = rgb2hsv(i.albedo.rgb);
    i.albedo.x += fmod(lerp(0, _Hue, i.hsvMask.r), 360);
    i.albedo.y = saturate(i.albedo.y * lerp(1, _Saturation, i.hsvMask.g));
    i.albedo.z *= lerp(1, _Value, i.hsvMask.b);
    i.albedo.rgb = hsv2rgb(i.albedo.rgb);

    i.diffuseColor.rgb = i.albedo.rgb;
    i.albedo.rgb *= (1-metallicSmoothness.x);
    half occlusion = lerp(1, i.occlusion.r, _OcclusionIntensity);
    indirectDiffuse *= lerp(occlusion, 1, _OcclusionMode);

    half4 lightCol = half4(0,0,0,0);
    calcLightCol(lightEnv, indirectDiffuse, lightCol);

    float3 vertexLightDiffuse = 0;
    float3 vertexLightSpec = 0;
    #if defined(VERTEXLIGHT_ON) && !defined(LIGHTMAP_ON)
        VertexLightInformation vLight = (VertexLightInformation)0;
        float4 vertexLightAtten = float4(0,0,0,0);
        float3 vertexLightColor = get4VertexLightsColFalloff(vLight, i.worldPos, i.normal, vertexLightAtten);
        float3 vertexLightDir = getVertexLightsDir(vLight, i.worldPos, vertexLightAtten);
        vertexLightDiffuse = getVertexLightsDiffuse(i, vLight);
        indirectDiffuse += vertexLightDiffuse;

        vertexLightSpec = getVertexLightSpecular(i, d, vLight, i.normal, dirs.viewDir, _AnisotropicSpecular) * occlusion;
    #endif

    half lightAvg = (dot(indirectDiffuse.rgb, grayscaleVec) + dot(lightCol.rgb, grayscaleVec)) / 2;
    half3 envMapBlurred = getEnvMap(i, d, 5, dirs.reflView, indirectDiffuse, i.normal);

    half4 ramp = 1;
    half4 diffuse = 1;
    #if defined(LIGHTMAP_ON)
        diffuse = i.albedo * getLightmap(t.uv1, i.normal, i.worldPos);
        #if defined(DYNAMICLIGHTMAP_ON)
            diffuse += getRealtimeLightmap(t.uv2, i.normal);
        #endif
    #else
        ramp = calcRamp(i,d);
        diffuse = calcDiffuse(i, d, indirectDiffuse, lightCol, ramp);
    #endif

    half4 rimLight = calcRimLight(i, d, lightCol, indirectDiffuse, envMapBlurred);
    half4 shadowRim = calcShadowRim(i, d, indirectDiffuse);

    float3 f0 = 0.16 * _Reflectivity * _Reflectivity * (1.0 - metallicSmoothness.r) + i.diffuseColor * metallicSmoothness.r;
    float3 fresnel = F_Schlick(d.vdn, f0);
    half3 indirectSpecular = calcIndirectSpecular(i, d, metallicSmoothness, reflViewAniso, indirectDiffuse, dirs.viewDir, fresnel, ramp) * occlusion;
    half3 directSpecular = calcDirectSpecular(i, d.ndl, d.ndh, d.vdn, d.ldh, lightCol, dirs.halfVector, _AnisotropicSpecular) * d.ndl * occlusion * i.attenuation;
    half4 subsurface = calcSubsurfaceScattering(i, d, dirs.lightDir, dirs.viewDir, i.normal, lightCol, indirectDiffuse);
    half4 outlineColor = calcOutlineColor(i, d, indirectDiffuse, lightCol);

    half lineHalftone = 0;
    half stipplingDirect = 0;
    half stipplingRim = 0;
    half stipplingIndirect = 0;
    bool usingLineHalftone = 0;
    if(_HalftoneType == 0 || _HalftoneType == 2)
    {
        lineHalftone = lerp(1, LineHalftone(i, 1), 1-saturate(dot(shadowRim * ramp, grayscaleVec)));
        usingLineHalftone = 1;
    }

    if(_HalftoneType == 1 || _HalftoneType == 2)
    {
        stipplingDirect = DotHalftone(i, saturate(dot(directSpecular, grayscaleVec))) * saturate(dot(shadowRim * ramp, grayscaleVec));
        stipplingRim = DotHalftone(i, saturate(dot(rimLight, grayscaleVec))) * saturate(dot(shadowRim * ramp, grayscaleVec));
        stipplingIndirect = DotHalftone(i, saturate(dot(indirectSpecular, grayscaleVec))) * saturate(dot(shadowRim * ramp, grayscaleVec));

        directSpecular *= stipplingDirect;
        rimLight *= stipplingRim;
        indirectSpecular *= lerp(0.5, 1, stipplingIndirect); // Don't want these to go completely black, looks weird
    }

    #if defined(Fur)
        AdjustFurSpecular(i, directSpecular.rgb, indirectSpecular.rgb);
    #endif

    half4 col = diffuse * shadowRim;
    calcReflectionBlending(i, col, indirectSpecular.xyzz);
    col += max(directSpecular.xyzz, rimLight);
    col.rgb += max(vertexLightSpec.rgb, rimLight);
    col += subsurface;
    calcClearcoat(col, i, d, untouchedNormal, indirectDiffuse, lightCol, dirs.viewDir, dirs.lightDir, ramp);
    col += calcEmission(i, t, d, lightAvg);
    float4 finalColor = lerp(col, outlineColor, i.isOutline) * lerp(1, lineHalftone, _HalftoneLineIntensity * usingLineHalftone);

    return finalColor;
}
