half4 BRDF_XSLighting(XSLighting i)
{
    float3 untouchedNormal = i.normal;
    calcNormal(i);
    
    bool lightEnv = any(_WorldSpaceLightPos0.xyz);
    half3 lightDir = calcLightDir(i);
    half3 viewDir = calcViewDir(i.worldPos);
    half3 stereoViewDir = calcStereoViewDir(i.worldPos);
    half4 metallicSmoothness = calcMetallicSmoothness(i);
    half3 halfVector = normalize(lightDir + viewDir);
    half3 reflView = calcReflView(viewDir, i.normal);
    half3 reflLight = calcReflLight(lightDir, i.normal);
    

    DotProducts d = (DotProducts)0;
    d.ndl = dot(i.normal, lightDir);
    d.vdn = abs(dot(viewDir, i.normal));
    d.vdh = DotClamped(viewDir, halfVector);
    d.tdh = dot(i.tangent, halfVector);
    d.bdh = dot(i.bitangent, halfVector);
    d.ndh = DotClamped(i.normal, halfVector);
    d.rdv = saturate(dot(reflLight, float4(-viewDir, 0)));
    d.ldh = DotClamped(lightDir, halfVector);
    d.svdn = abs(dot(stereoViewDir, i.normal));
    
    i.albedo.rgb *= (1-metallicSmoothness.x);
    i.albedo.rgb = lerp(dot(i.albedo.rgb, grayscaleVec), i.albedo.rgb, _Saturation);
    i.diffuseColor.rgb = lerp(dot(i.diffuseColor.rgb, grayscaleVec), i.diffuseColor.rgb, _Saturation);

    #if defined(VERTEXLIGHT_ON)
        half3 indirectDiffuse = calcIndirectDiffuse() + get4VertexLightsColFalloff(i.worldPos, i.normal);   
    #else
        half3 indirectDiffuse = calcIndirectDiffuse();
    #endif

    half4 lightCol = half4(0,0,0,0);
    calcLightCol(lightEnv, indirectDiffuse, lightCol);

    half lightAvg = (indirectDiffuse.r + indirectDiffuse.g + indirectDiffuse.b + lightCol.r + lightCol.g + lightCol.b) / 6;

    half4 ramp = calcRamp(i,d);
    half4 diffuse = calcDiffuse(i, d, indirectDiffuse, lightCol, ramp);
    half4 rimLight = calcRimLight(i, d, lightCol, indirectDiffuse);
    half4 shadowRim = calcShadowRim(i, d, indirectDiffuse);
    half3 indirectSpecular = calcIndirectSpecular(i, d, metallicSmoothness, reflView, indirectDiffuse, viewDir, ramp);
    half3 directSpecular = calcDirectSpecular(i, d, lightCol, indirectDiffuse, metallicSmoothness, _AnisotropicAX * 0.1, _AnisotropicAY * 0.1);
    half4 subsurface = calcSubsurfaceScattering(i, d, lightDir, viewDir, i.normal, lightCol, indirectDiffuse);
    half4 occlusion = lerp(_OcclusionColor, 1, i.occlusion.r);
    half4 outlineColor = calcOutlineColor(i, d, indirectDiffuse, lightCol);

    half4 col;
    col = diffuse * shadowRim;
    calcReflectionBlending(i, col, indirectSpecular.xyzz);
    col += max(directSpecular.xyzz, rimLight);
    col += subsurface;
    col *= occlusion;
    calcClearcoat(col, i, d, untouchedNormal, indirectDiffuse, lightCol, viewDir, lightDir, ramp);
    col += calcEmission(i, lightAvg);

    float4 finalColor = lerp(col, outlineColor, i.isOutline);
    return finalColor;
}