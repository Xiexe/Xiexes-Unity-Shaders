half4 BRDF_XSLighting(XSLighting i)
{
    float3 untouchedNormal = i.normal;
    calcNormal(i);
    
    half4 vertexLightAtten = half4(0,0,0,0); 
    #if defined(VERTEXLIGHT_ON)
        half3 indirectDiffuse = calcIndirectDiffuse(i) + get4VertexLightsColFalloff(i.worldPos, i.normal, vertexLightAtten);   
    #else
        half3 indirectDiffuse = calcIndirectDiffuse(i);
    #endif

    bool lightEnv = any(_WorldSpaceLightPos0.xyz);
    half3 lightDir = calcLightDir(i, vertexLightAtten);
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
    
    i.albedo.rgb = rgb2hsv(i.albedo.rgb);
    i.albedo.x += fmod(lerp(0, _Hue, i.hsvMask.r), 360);
    i.albedo.y = saturate(i.albedo.y * lerp(1, _Saturation, i.hsvMask.g));
    i.albedo.z *= lerp(1, _Value, i.hsvMask.b);
    i.albedo.rgb = hsv2rgb(i.albedo.rgb);

    i.diffuseColor.rgb = i.albedo.rgb;
    i.albedo.rgb *= (1-metallicSmoothness.x);

    half4 lightCol = half4(0,0,0,0);
    calcLightCol(lightEnv, indirectDiffuse, lightCol);

    half lightAvg = (indirectDiffuse.r + indirectDiffuse.g + indirectDiffuse.b + lightCol.r + lightCol.g + lightCol.b) / 6;
    half3 envMapBlurred = getEnvMap(i, d, 5, reflView, indirectDiffuse, i.normal);

    half4 ramp = calcRamp(i,d);
    half4 diffuse = calcDiffuse(i, d, indirectDiffuse, lightCol, ramp);
    half4 rimLight = calcRimLight(i, d, lightCol, indirectDiffuse, envMapBlurred);
    half4 shadowRim = calcShadowRim(i, d, indirectDiffuse);
    half3 indirectSpecular = calcIndirectSpecular(i, d, metallicSmoothness, reflView, indirectDiffuse, viewDir, ramp);
    half3 directSpecular = calcDirectSpecular(i, d, lightCol, indirectDiffuse, metallicSmoothness, _AnisotropicAX * 0.1, _AnisotropicAY * 0.1);
    half4 subsurface = calcSubsurfaceScattering(i, d, lightDir, viewDir, i.normal, lightCol, indirectDiffuse);
    half4 occlusion = lerp(_OcclusionColor, 1, i.occlusion.r);
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
    
    #if defined(Glass)
        float4 backgroundColor = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(i.screenPos + (float4(i.normal,0) * _IOR)));
    #endif

    half4 col;
    #if !defined(Glass)
        col = diffuse * shadowRim;
    #else
        col = backgroundColor;
    #endif
    calcReflectionBlending(i, col, indirectSpecular.xyzz);
    col += max(directSpecular.xyzz, rimLight);
    col += subsurface;
    col *= occlusion;
    calcClearcoat(col, i, d, untouchedNormal, indirectDiffuse, lightCol, viewDir, lightDir, ramp);
    col += calcEmission(i, lightAvg);

    float4 finalColor = lerp(col, outlineColor, i.isOutline) * lerp(1, lineHalftone, _HalftoneLineIntensity * usingLineHalftone);
    //finalColor = lerp(finalColor, float4(i.color.rgb, 1), 0.9999);
    return finalColor;
}