

float4 lighting(XSLighting i)
{   
    
    half4 lightCol = _LightColor0;
    half2 metallicSmoothness = calcMetallicSmoothness(i);
    half3 viewDir = calcViewDir(i.worldPos);
    half3 stereoViewDir = calcStereoViewDir(i.worldPos);
    half3 lightDir = calcLightDir(i.worldPos);
    half3 halfVector = normalize(lightDir + viewDir);

    //Reflection Vectors
        half3 reflView = reflect(-viewDir, i.worldNormal);
        half3 reflLight = reflect(lightDir, i.worldNormal);
    //----

	//Dot Products
        DotProducts d = (DotProducts)0;
		d.ndl = calcNdL(i.worldNormal, lightDir, i.attenuation);
        d.vdn = abs(dot(viewDir, i.normal));
        d.vdh = DotClamped(viewDir, halfVector);
        d.tdh = dot(i.tangent, halfVector);
        d.bdh = dot(i.bitangent, halfVector);
        d.ndh = DotClamped(i.worldNormal, halfVector);
        d.rdv = saturate( dot( reflLight, float4(-viewDir, 0) ));
        d.ldh = DotClamped(lightDir, halfVector);
	//------------

    //Indirect 
        half3 indirectDiffuse = calcIndirectDiffuse();
        half3 indirectSpecular = calcIndirectSpecular(i.albedo, metallicSmoothness, reflView);
	//--------

    //Direct
        half3 directSpecular = calcDirectSpecular(i, d, lightCol, indirectDiffuse, metallicSmoothness, _AnisotropicAX * 0.1, _AnisotropicAY * 0.1);
	//--------

    //Ramp
        float4 ramp = calcRamp(i, d, indirectDiffuse);
        float rampAvg = (ramp.r + ramp.g + ramp.b) * 0.33333;
        float indirectAvg = (indirectDiffuse.r + indirectDiffuse.g + indirectDiffuse.b) * 0.33333;
    //--------

    float4 light;
    UNITY_BRANCH
    if (_RampMode == 0) // Mixed
        light = (lightCol + indirectDiffuse.xyzz) * ramp;
    else // Ramp
        light = (lightCol + indirectAvg) * ramp;
    
    light *= i.attenuation + indirectDiffuse.xyzz;

	float4 col;
	col = i.albedo * (1-metallicSmoothness.x);
	col += indirectSpecular.xyzz;
    col += directSpecular.xyzz;

	return col * light;
}