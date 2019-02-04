half3 calcNormal(XSLighting i)
{
	
	half3 nMap = UnpackNormal(i.normalMap);//UnpackNormal(tex2D(i.normalMap, uv));
	
	half3 calcedNormal = half3( i.bitangent * nMap.r + 
								i.tangent * nMap.g +
								i.normal * nMap.b  );

	return normalize(calcedNormal);
}

half calcNdL(half3 worldNormal, half3 lightDir, half attenuation)
{	
	//This will be used to map received shadows based on the shadow ramp, but will keep a specialized look for point and spot lights.
	//This is a look I prefer, however if you change this to always multiply by attenuation it would work for Point and Spot lights too.
	half ndl = dot(worldNormal, lightDir);
	#if defined(DIRECTIONAL)
		ndl *= attenuation; 
	#endif
	return ndl;
}

half3 calcViewDir(half3 worldPos)
{
	half3 viewDir = _WorldSpaceCameraPos - worldPos;
	return normalize(viewDir);
}

half3 calcStereoViewDir(half3 worldPos)
{
	#if UNITY_SINGLE_PASS_STEREO
		float3 cameraPos = float3((unity_StereoWorldSpaceCameraPos[0]+ unity_StereoWorldSpaceCameraPos[1])*.5); 
	#else
		float3 cameraPos = _WorldSpaceCameraPos;
	#endif
		float3 viewDir = cameraPos - worldPos;
	return normalize(viewDir);
}

half3 calcLightDir(half3 worldPos)
{
	int lightEnv = int(any(_WorldSpaceLightPos0.xyz));
	half3 lightDir;
    #if defined(DIRECTIONAL)
        lightDir = _WorldSpaceLightPos0;
    #else
        lightDir = _WorldSpaceLightPos0 - worldPos;
    #endif
    if(lightEnv != 1)
    {
        lightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
        #if !defined(POINT) && !defined(SPOT)
            if(length(unity_SHAr.xyz*unity_SHAr.w + unity_SHAg.xyz*unity_SHAg.w + unity_SHAb.xyz*unity_SHAb.w) == 0)
            {
                lightDir = float4(1, 1, 1, 0);
            } 
        #endif
    }
	return normalize(lightDir);
}

//Direct Lighting Fuctions
	// From HDRenderPipeline
	float D_GGXAnisotropic(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
	{
		float f = TdotH * TdotH / (roughnessT * roughnessT) + BdotH * BdotH / (roughnessB * roughnessB) + NdotH * NdotH;
		return 1.0 / (roughnessT * roughnessB * f * f);
	}

	half3 calcDirectSpecular(half4 albedo, float tdh, float bdh, float ndh, float rdv, float ax, float ay)
	{
		if(_SpecMode == 0)
		{
			half reflectionUntouched = saturate(pow(rdv, _SpecularArea * 128));
			return lerp(reflectionUntouched, round(reflectionUntouched), _SpecularStyle) * _SpecularIntensity * albedo;
		}
		else
		{
			half smooth = saturate(D_GGXAnisotropic(tdh, bdh, ndh, ax, ay));
			half sharp = round(smooth) * 2 * 0.5;
			return lerp(smooth, sharp, _SpecularStyle) * _SpecularIntensity * albedo;
		}
	}
//----

//Indirect Lighting functions
	half3 calcIndirectDiffuse()
	{
		return ShadeSH9(float4(0, 0, 0, 1)); //Just get the Lightprobe Color information
	}

	half3 calcIndirectSpecular(half3 reflDir, half4 albedo)
	{
		half roughness = (1-_Glossiness);
		roughness *= 1.7 - 0.7 * roughness;
						
		half4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, roughness * UNITY_SPECCUBE_LOD_STEPS);
		half3 indirectSpecular = DecodeHDR(envSample, unity_SpecCube0_HDR);

		half3 indirectLighting = indirectSpecular * albedo;
		return indirectLighting;
	}
//----