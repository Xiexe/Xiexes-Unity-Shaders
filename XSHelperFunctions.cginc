
//Helper Functions for Reflections
	inline half3 XSFresnelTerm (half3 F0, half cosA)
	{
		half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
		return F0 + (1-F0) * t;
	}
	inline half3 XSFresnelLerp (half3 F0, half3 F90, half cosA)
	{
		half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
		return lerp (F0, F90, t);
	}

	inline half XSGGXTerm (half NdotH, half roughness)
	{
		half a2 = roughness * roughness;
		half d = (NdotH * a2 - NdotH) * NdotH + 1.0f; // 2 mad
		return UNITY_INV_PI * a2 / (d * d + 1e-7f); // This function is not intended to be running on Mobile,
												// therefore epsilon is smaller than what can be represented by half
	}
	float3 F_Schlick(float3 SpecularColor, float VoH)
	{
		return SpecularColor + (1.0 - SpecularColor) * exp2((-5.55473 * VoH) - (6.98316 * VoH));
	}
//

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
	half3 lightDir = UnityWorldSpaceLightDir(worldPos);

    if(lightEnv != 1)
    {
        lightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
        // #if !defined(POINT) && !defined(SPOT)
        //     if(length(unity_SHAr.xyz*unity_SHAr.w + unity_SHAg.xyz*unity_SHAg.w + unity_SHAb.xyz*unity_SHAb.w) == 0)
        //     {
        //         lightDir = float4(1, 1, 1, 0);
        //     } 
        // #endif
    }
	return normalize(lightDir);
}

half2 calcMetallicSmoothness(XSLighting i)
{
	half roughness = 1-(_Glossiness * i.metallicGlossMap.a);
	roughness *= 1.7 - 0.7 * roughness;

	half metallic = i.metallicGlossMap.r * _Metallic;

	return half2(metallic, roughness);
}

//Direct Lighting Fuctions
	// From HDRenderPipeline
	float D_GGXAnisotropic(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
	{
		float f = TdotH * TdotH / (roughnessT * roughnessT) + BdotH * BdotH / (roughnessB * roughnessB) + NdotH * NdotH;
		return 1.0 / (roughnessT * roughnessB * f * f);
	}

	half3 calcDirectSpecular(XSLighting i, DotProducts d, half4 lightCol, half3 indirectDiffuse, float2 metallicSmoothness, float ax, float ay)
	{	
		lightCol = lightCol + indirectDiffuse.xyzz;
		float specularIntensity = _SpecularIntensity * i.specularMap;
		if(_SpecMode == 0)
		{
			half3 reflectionUntouched = saturate(pow(d.rdv, _SpecularArea * 128));
			reflectionUntouched *= lightCol;
			return lerp(reflectionUntouched, round(reflectionUntouched), _SpecularStyle) * specularIntensity;
		}
		else if(_SpecMode == 1)
		{
			half smooth = saturate(D_GGXAnisotropic(d.tdh, d.bdh, d.ndh, ax, ay));
			half sharp = round(smooth) * 2 * 0.5;
			return lerp(smooth, sharp, _SpecularStyle) * lightCol * specularIntensity;
		}
		else
		{
			float sndl = saturate(d.ndl);	
			float roughness = 1-(_SpecularArea);
			float V = SmithJointGGXVisibilityTerm(sndl, d.vdn, roughness);
			float F = F_Schlick(float3(0.0, 0.0, 0.0), d.ldh);
			float D = XSGGXTerm(d.ndh, roughness*roughness);


			float reflection = V * D * UNITY_PI;
			return (max(0, reflection * sndl) * F * i.attenuation) * lightCol * specularIntensity;
		}
	}
//----

//Indirect Lighting functions
	half3 calcIndirectDiffuse()
	{
		return ShadeSH9(float4(0, 0, 0, 1)); //Just get the Lightprobe Color information
	}

	half3 calcIndirectSpecular(float3 albedo, float2 metallicSmoothness, half3 reflDir)
	{	
		half4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, metallicSmoothness.y * UNITY_SPECCUBE_LOD_STEPS);
		half3 indirectSpecular = DecodeHDR(envSample, unity_SpecCube0_HDR);
		
		half3 indirectLighting = indirectSpecular * (albedo * metallicSmoothness.x);

		return indirectLighting;
	}
//----

//Ramp
	float4 calcRamp(XSLighting i, DotProducts d, float3 indirectDiffuse)
	{
		float remapRamp; 

        // #if defined(DIRECTIONAL)
        //     remapRamp = saturate(d.ndl * i.attenuation) * 0.5 + 0.5;
        // #else 
            remapRamp = d.ndl * 0.5 + 0.5;
        // #endif

        float4 ramp = tex2D( _Ramp, float2(remapRamp, remapRamp) );
        
        return ramp;
	}
//----
