half4 BRDF_XSLighting(HookData data)
{
    FragmentData i = data.i;
    float3 untouchedNormal = data.untouchedNormal;
    TextureUV t = data.t;
    Directions dirs = data.dirs;
    DotProducts d = data.d;
    PassLights lights = data.lights;
    lights.mainLight.type = LIGHT_TYPE_MAIN;
    lights.ambientLight.type = LIGHT_TYPE_AMBIENT;

    half4 metallicSmoothness = calcMetallicSmoothness(i);
    half3 reflViewAniso = getAnisotropicReflectionVector(dirs.viewDir, i.bitangent, i.tangent, i.normal, metallicSmoothness.a, _AnisotropicReflection);
    half occlusion = lerp(1, i.occlusion.r, _OcclusionIntensity);

    i.albedo.rgb = rgb2hsv(i.albedo.rgb);
    i.albedo.x += fmod(lerp(0, _Hue, i.hsvMask.r), 360);
    i.albedo.y = saturate(i.albedo.y * lerp(1, _Saturation, i.hsvMask.g));
    i.albedo.z *= lerp(1, _Value, i.hsvMask.b);
    i.albedo.rgb = hsv2rgb(i.albedo.rgb);
    i.diffuseColor.rgb = i.albedo.rgb;
    i.albedo.rgb *= (1-metallicSmoothness.x);
    
    bool isRealtimeLighting = any(_WorldSpaceLightPos0.xyz);
    half3 totalDiffuseLight = half3(0,0,0);
    half3 totalSpecularLight = half3(0,0,0);
    half3 totalSubsurfaceScattering = half3(0,0,0);
    
    half3 ambientColor = GetAmbientColor();
    ambientColor = isRealtimeLighting ? ambientColor : ambientColor * 0.4;

    half3 mainLightColor = _LightColor0;
    mainLightColor = isRealtimeLighting ? mainLightColor : ambientColor * 0.6;
    
    PopulateLight(i, dirs, mainLightColor, i.attenuation, GetDominantLightDirection(i), lights.mainLight);
    PopulateLight(i, dirs, ambientColor, 1, half3(0,0,0), lights.ambientLight);
    lights.ambientLight.color *= lerp(occlusion, 1, _OcclusionMode);
    
    PopulateExtraPassLights(i, dirs, lights.extraLights);
    
    ApplyMainLights(i, d, t, dirs, lights.mainLight, lights.ambientLight, totalDiffuseLight, totalSpecularLight, totalSubsurfaceScattering);
    ApplyExtraPassLights(i, d, t, dirs, lights.extraLights, totalDiffuseLight, totalSpecularLight, totalSubsurfaceScattering);
    i.surfaceColor = i.albedo * totalDiffuseLight;

    half3 environmentMap = getEnvMap(i, d, 5, dirs.reflView, lights.ambientLight.color, i.normal);

    half3 rimLight = GetRimLight(i, d, lights.mainLight, lights.ambientLight, environmentMap);
    half3 rimShadow = GetRimShadow(i, d, lights.mainLight, lights.ambientLight);

    float3 f0 = 0.16 * _Reflectivity * _Reflectivity * (1.0 - metallicSmoothness.r) + i.diffuseColor * metallicSmoothness.r;
    float3 fresnel = F_Schlick(d.vdn, f0);
    half3 indirectSpecular = GetIndirectSpecular(i, metallicSmoothness, reflViewAniso, lights.ambientLight.color, dirs.viewDir, fresnel);
    DoReflectionBlending(i, i.surfaceColor, indirectSpecular);
    totalSpecularLight += indirectSpecular;
    totalSpecularLight *= occlusion;
    
    #if defined(Fur)
        AdjustFurSpecular(i, totalSpecularLight.rgb);
    #endif
    
    ApplyHalftones(i, totalSpecularLight, rimLight, rimShadow, totalDiffuseLight);

    i.surfaceColor += max(totalSpecularLight, rimLight);
    i.surfaceColor += totalSpecularLight;
    i.surfaceColor += totalSubsurfaceScattering;
    i.surfaceColor *= rimShadow;

    half lightAvg = (dot(lights.ambientLight.color.rgb, grayscaleVec) + dot(lights.mainLight.color.rgb, grayscaleVec)) / 2;
    i.surfaceColor += GetEmission(i, t, d, lightAvg);

    i.surfaceColor = lerp(i.surfaceColor, GetOutlineColor(i, lights.mainLight, lights.ambientLight), i.isOutline);
    return float4(i.surfaceColor, 1);
    // TODO:: Add back in clearcoat support.
    // calcClearcoat(col, i, d, untouchedNormal, indirectDiffuse, lightCol, dirs.viewDir, dirs.lightDir, ramp);
}
