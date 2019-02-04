float4 lighting(XSLighting i)
{
    half4 lightCol = _LightColor0;
    half3 viewDir = calcViewDir(i.worldPos);
    half3 stereoViewDir = calcStereoViewDir(i.worldPos);
    half3 lightDir = calcLightDir(i.worldPos);
    half3 halfVector = normalize(lightDir + viewDir);

    //Reflection Vectors
        half3 reflView = reflect(-viewDir, i.worldNormal);
        half3 reflLight = reflect(lightDir, i.worldNormal);
    //----

	//Dot Products
		half ndl = calcNdL(i.worldNormal, lightDir, i.attenuation);
        half tdh = dot(i.tangent, halfVector);
        half bdh = dot(i.bitangent, halfVector);
        half ndh = DotClamped(i.worldNormal, halfVector);
        half rdv = saturate( dot( reflLight, float4(-viewDir, 0) ));
	//------------
    
    //Direct
        half3 directSpecular = calcDirectSpecular(i.albedo, tdh, bdh, ndh, rdv, _AnisotropicAX * 0.1, _AnisotropicAY * 0.1);
	//--------

	//Indirect 
        half3 indirectDiffuse = calcIndirectDiffuse();
        half3 indirectSpecular = calcIndirectSpecular(reflView, i.albedo); // Calculate indirect Specularity
	//--------

    //Ramp
        float remapRamp = ndl * 0.5 + 0.5;
        float4 ramp = tex2D( _Ramp, float2(remapRamp, remapRamp) );
        
        #if !defined(DIRECTIONAL)
            ramp *= i.attenuation;
        #endif

        float rampAvg = (ramp.r + ramp.g + ramp.b) * 0.33333;
        float indirectAvg = (indirectDiffuse.r + indirectDiffuse.g + indirectDiffuse.b) * 0.33333;
    //--------

    float4 light;
    if(_RampMode == 0)// Ambient
    {
        light = (lightCol + indirectDiffuse.xyzz) * rampAvg;
    }
    else
    {   
        if (_RampMode == 1) // Mixed
            light = (lightCol + indirectDiffuse.xyzz) * ramp;
        else // Ramp
            light = (lightCol + indirectAvg) * ramp;
    }

	float4 col;
	
	col = i.albedo * (1-_Metallic);
	col += indirectSpecular.xyzz;
    col += directSpecular.xyzz;

	return col * light;
}