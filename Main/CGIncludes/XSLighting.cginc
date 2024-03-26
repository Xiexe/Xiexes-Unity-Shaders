half4 BRDF_XSLighting(HookData data)
{
    SurfaceLightInfo lightInfo = data.lightInfo;
    FragmentData i = data.frag;
    TextureUV t = data.uvs;
    Directions dirs = data.dirs;
    DotProducts d = data.dots;
    PassLights lights = data.lights;

    InitializeSurface(i);

    PopulateLight(i, dirs, GetAmbientColor(i.occlusion), 1, GetProbeLightDirection(), LIGHT_TYPE_AMBIENT, lights.ambientLight);
    PopulateLight(i, dirs, _LightColor0, i.attenuation, GetLightDirection(i), LIGHT_TYPE_MAIN, lights.mainLight);
    PopulateExtraPassLights(i, dirs, lights.extraLights);

    AccumulateLight(i, d, t, dirs, lights.ambientLight, lightInfo);
    AccumulateLight(i, d, t, dirs, lights.mainLight, lightInfo);
    AccumulateExtraPassLights(i, d, t, dirs, lights.extraLights, lightInfo);
    ApplyAccumulatedDiffuseLightToSurface(i, lightInfo);

    AccumulateIndirectSpecularLight(i, dirs, d, lights, i.occlusion, lightInfo);
    ApplyAccumulatedIndirectSpecularLightToSurface(i, lightInfo);
    ApplyAccumulatedDirectSpecularLightToSurface(i, i.occlusion, lightInfo);
    
    half3 environmentMap = getEnvMap(i, d, 5, dirs.reflView, lights.ambientLight.color, i.normal);
    half3 rimLight = GetRimLight(i, d, lights.mainLight, lights.ambientLight, environmentMap);
    half3 rimShadow = GetRimShadow(i, d, lights.mainLight, lights.ambientLight);

    #if defined(Fur)
        AdjustFurSpecular(i, lightInfo);
    #endif
    
    ApplyHalftones(i, lightInfo, rimLight, rimShadow);

    i.surfaceColor += max(lightInfo.directSpecular, rimLight);
    i.surfaceColor += lightInfo.subsurface;
    i.surfaceColor *= rimShadow;
    i.surfaceColor += GetEmission(i, t, d, lights);
    i.surfaceColor = lerp(i.surfaceColor, GetOutlineColor(i, lights.mainLight, lights.ambientLight), i.isOutline);
    return float4(i.surfaceColor, 1);
    // TODO:: Add back in clearcoat support.
    // TODO:: Add back in lightmapping support for the fur shader.
    // calcClearcoat(col, i, d, untouchedNormal, indirectDiffuse, lightCol, dirs.viewDir, dirs.lightDir, ramp);
}
