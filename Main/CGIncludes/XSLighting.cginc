half4 XSLighting_BRDF_Toon(XSLighting i)
{   
    calcNormal(i);
    
    int lightEnv = int(any(_WorldSpaceLightPos0.xyz));
    half3 lightDir = calcLightDir(i);
    half3 viewDir = calcViewDir(i.worldPos);
    half3 stereoViewDir = calcStereoViewDir(i.worldPos);
    half4 metallicSmoothness = calcMetallicSmoothness(i);
    half3 halfVector = normalize(lightDir + viewDir);

    half3 reflView = reflect(-viewDir, i.normal);
    half3 reflLight = reflect(lightDir, i.normal);

    DotProducts d = (DotProducts)0;
    d.ndl = dot(i.normal, lightDir);
    d.vdn = abs(dot(viewDir, i.normal));
    d.vdh = DotClamped(viewDir, halfVector);
    d.tdh = dot(i.tangent, halfVector);
    d.bdh = dot(i.bitangent, halfVector);
    d.ndh = DotClamped(i.normal, halfVector);
    d.rdv = saturate( dot( reflLight, float4(-viewDir, 0) ));
    d.ldh = DotClamped(lightDir, halfVector);
    d.svdn = abs(dot(stereoViewDir, i.normal));

    i.albedo.rgb *= (1-metallicSmoothness.x); 
    half3 indirectDiffuse = calcIndirectDiffuse();
    half4 lightCol = calcLightCol(lightEnv, indirectDiffuse);
    
    half4 ramp = calcRamp(i,d);
    half4 diffuse = calcDiffuse(i, d, indirectDiffuse, lightCol, ramp);
    half3 indirectSpecular = calcIndirectSpecular(i, d, metallicSmoothness, reflView, indirectDiffuse, viewDir, ramp);
    half4 rimLight = calcRimLight(i, d, lightCol, indirectDiffuse);
    half4 shadowRim = calcShadowRim(i, d, indirectDiffuse);
    half3 directSpecular = calcDirectSpecular(i, d, lightCol, indirectDiffuse, metallicSmoothness, _AnisotropicAX * 0.1, _AnisotropicAY * 0.1);
    half4 subsurface = calcSubsurfaceScattering(i, d, lightDir, viewDir, i.normal, lightCol, indirectDiffuse);
    half4 outlineColor = calcOutlineColor(i, d, indirectDiffuse, lightCol);
    half4 occlusion = lerp(1, _OcclusionColor, 1-i.occlusion);

	half4 col;
    col = diffuse * shadowRim;
    col += indirectSpecular.xyzz;
    col += directSpecular.xyzz;
    col += rimLight;
    col += subsurface;
    col *= occlusion;
	col += i.emissionMap;

	col = lerp(dot(col, grayscaleVec), col, _Saturation);

    float4 finalColor = lerp(col, outlineColor, i.isOutline);

	return finalColor;
}