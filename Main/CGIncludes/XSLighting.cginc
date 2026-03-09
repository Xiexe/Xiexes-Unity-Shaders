half4 BRDF_XSLighting(HookData data)
{
    SurfaceLightInfo lightInfo = data.lightInfo;
    FragmentData i = data.frag;
    TextureUV t = data.uvs;
    Directions dirs = data.dirs;
    DotProducts d = data.dots;
    PassLights lights = data.lights;

    InitializeSurface(i, lightInfo);
    
    half3 lightDirection = GetLightDirection(i);
    PopulateLight(i, dirs, _LightColor0, i.attenuation, lightDirection, _WorldSpaceLightPos0, LIGHT_TYPE_MAIN, lights.mainLight);
    PopulateLight(i, dirs, GetAmbientColor(i.worldPos, i.occlusion), 0, lightDirection, half3(0,0,0), LIGHT_TYPE_AMBIENT, lights.ambientLight);
    PopulateExtraPassLights(i, dirs, lights.extraLights);

    AccumulateLight(i, d, t, dirs, lights.mainLight, lightInfo);

    #if defined(UNITY_PASS_FORWARDBASE)
        AccumulateLight(i, d, t, dirs, lights.ambientLight, lightInfo);
        AccumulateExtraPassLights(i, d, t, dirs, lights.extraLights, lightInfo);
    #endif
    
    // Adjust lighting using the shadow ramp or shadow color.
    ApplyShadingAdjustments(i, lightInfo, t, lights.ambientLight);
    
    AccumulateIndirectSpecularLight(i, dirs, d, lights, i.occlusion, lightInfo);
    half3 environmentMap = getEnvMap(i, d, 5, dirs.reflView, lights.ambientLight.color, i.normal);
    half3 rimLight = GetRimLight(i, d, lights.mainLight, lights.ambientLight, environmentMap);
    half3 rimShadow = GetRimShadow(i, d, lights.mainLight, lights.ambientLight);

    #if defined(Fur)
        AdjustFurSpecular(i, lightInfo);
    #endif
    
    ApplyAccumulatedIndirectSpecularLightToSurface(i, lightInfo);
    ApplyAccumulatedDirectSpecularLightToSurface(i, i.occlusion, lightInfo);
    ApplyHalftones(i, lightInfo, rimLight, rimShadow);

    // i.surfaceColor += rimLight;
    // i.surfaceColor += lightInfo.subsurface;
    // i.surfaceColor *= rimShadow;
    // i.surfaceColor += GetEmission(i, t, d, lights);
    // i.surfaceColor = lerp(i.surfaceColor, GetOutlineColor(i, lights.mainLight, lights.ambientLight), i.isOutline);
    return float4(i.surfaceColor, 1);
    // TODO:: Add back in lightmapping support.
}
