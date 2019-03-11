

//Helper Functions for Reflections
	half3 XSFresnelTerm (half3 F0, half cosA)
	{
		half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
		return F0 + (1-F0) * t;
	}
	
	half3 XSFresnelLerp (half3 F0, half3 F90, half cosA)
	{
		half t = Pow5 (1 - cosA);   // ala Schlick interpoliation
		return lerp (F0, F90, t);
	}

	half XSGGXTerm (half NdotH, half roughness)
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

		// From HDRenderPipeline
	float D_GGXAnisotropic(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
	{	
		float f = TdotH * TdotH / (roughnessT * roughnessT) + BdotH * BdotH / (roughnessB * roughnessB) + NdotH * NdotH;
		float aniso = 1.0 / (roughnessT * roughnessB * f * f);
		return aniso;
	}
//

// Get the most intense light Dir from probes OR from a light source. Method developed by Xiexe / Merlin
half3 calcLightDir(XSLighting i)
{
	half3 lightDir = UnityWorldSpaceLightDir(i.worldPos);
	lightDir *= i.attenuation * dot(_LightColor0, grayscaleVec);//Use only probe direction in shadows by masking out the light dir with attenuation.

	half3 probeLightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
	lightDir = (lightDir + probeLightDir); //Make light dir the average of the probe direction and the light source direction.

		#if !defined(POINT) && !defined(SPOT) // if the average length of the light probes is null, and we don't have a directional light in the scene, fall back to our fallback lightDir
			if(length(unity_SHAr.xyz*unity_SHAr.w + unity_SHAg.xyz*unity_SHAg.w + unity_SHAb.xyz*unity_SHAb.w) == 0 && ((_LightColor0.r+_LightColor0.g+_LightColor0.b) / 3) < 0.1)
			{
				lightDir = float4(1, 1, 1, 0);
			}
		#endif

	return normalize(lightDir);
}

half4 calcLightCol(int lightEnv, float3 indirectDiffuse)
{
	//If we don't have a directional light or realtime light in the scene, we can derive light color from a slightly
	//Modified indirect color. 
	half4 lightCol = _LightColor0; 

	if(lightEnv != 1)
		lightCol = indirectDiffuse.xyzz * 0.2; 

	return lightCol;	
}

half4 calcMetallicSmoothness(XSLighting i)
{
	half roughness = 1-(_Glossiness * i.metallicGlossMap.a);
	roughness *= 1.7 - 0.7 * roughness;

	half metallic = i.metallicGlossMap.r * _Metallic;
	half reflectionMask = 1-i.metallicGlossMap.b;

	return half4(metallic, 0, reflectionMask, roughness);
}

half4 calcRimLight(XSLighting i, DotProducts d, half4 lightCol, half3 indirectDiffuse)
{	
	half rimIntensity = saturate((1-d.svdn) * pow(d.ndl, _RimThreshold));
	rimIntensity = smoothstep(_RimRange - _RimSharpness, _RimRange + _RimSharpness, rimIntensity);
	half4 rim = (rimIntensity * _RimIntensity * (lightCol + indirectDiffuse.xyzz) * i.albedo * i.attenuation);
	// float dotHalftone = 1-DotHalftone(i, rimIntensity);
	// rim *= dotHalftone;
	
	return rim;
}

half4 calcShadowRim(XSLighting i, DotProducts d, half3 indirectDiffuse)
{
	half rimIntensity = saturate((1-d.svdn) * pow(-d.ndl, _ShadowRimThreshold * 2));
	rimIntensity = smoothstep(_ShadowRimRange - _ShadowRimSharpness, _ShadowRimRange + _ShadowRimSharpness, rimIntensity);
	half4 shadowRim = lerp(1, _ShadowRim + (indirectDiffuse.xyzz * 0.1), rimIntensity);

	return shadowRim;
}

half3 calcDirectSpecular(XSLighting i, DotProducts d, half4 lightCol, half3 indirectDiffuse, half4 metallicSmoothness, half ax, half ay)
{	
	float specularIntensity = _SpecularIntensity * i.specularMap.r;
	half3 specular = half3(0,0,0);
	half smoothness = max(0.01, (_SpecularArea * i.specularMap.b));
	smoothness *= 1.7 - 0.7 * smoothness;
	
	if(_SpecMode == 0)
	{
		half reflectionUntouched = saturate(pow(d.rdv, smoothness * 128));
		//float dotHalftone = 1-DotHalftone(i, reflectionUntouched);
		specular = lerp(reflectionUntouched, round(reflectionUntouched), _SpecularStyle) * specularIntensity * (_SpecularArea * 2) ;
		specular *= i.attenuation;
	}
	else if(_SpecMode == 1)
	{
		half smooth = saturate(D_GGXAnisotropic(d.tdh, d.bdh, d.ndh, ax, ay));
		half sharp = round(smooth) * 2 * 0.5;
		specular = lerp(smooth, sharp, _SpecularStyle) * specularIntensity;
		specular *= i.attenuation;
	}
	else if(_SpecMode == 2)
	{
		half sndl = saturate(d.ndl);	
		half roughness = 1-smoothness;
		half V = SmithJointGGXVisibilityTerm(sndl, d.vdn, roughness);
		half F = F_Schlick(half3(0.0, 0.0, 0.0), d.ldh);
		half D = XSGGXTerm(d.ndh, roughness*roughness);

		half reflection = V * D * UNITY_PI;
		half smooth = (max(0, reflection * sndl) * F * i.attenuation) * specularIntensity;
		half sharp = round(smooth);
		specular = lerp(smooth, sharp, _SpecularStyle);
	}
	specular *= lightCol;
	float3 tintedAlbedoSpecular = specular * i.albedo;
	specular = lerp(specular, tintedAlbedoSpecular, _SpecularAlbedoTint * i.specularMap.g); // Should specular highlight be tinted based on the albedo of the object?
	return specular;
}

half3 calcIndirectSpecular(XSLighting i, DotProducts d, float4 metallicSmoothness, half3 reflDir, half3 indirectLight, float3 viewDir, half4 ramp)
{	//This function handls Unity style reflections, Matcaps, and a baked in fallback cubemap.
		half3 spec = half3(0,0,0);

		//Indirect specular should only happen in the forward base pass. Otherwise each extra light adds another indirect sample, which could mean you're getting too much light. 
		#if defined(UNITY_PASS_FORWARDBASE)
			half lightAvg = (indirectLight.r + indirectLight.g + indirectLight.b + _LightColor0.r + _LightColor0.g + _LightColor0.b) / 6;

			UNITY_BRANCH
			if(_ReflectionMode == 0) // PBR
			{
				float3 reflectionUV1 = getReflectionUV(reflDir, i.worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
				half4 probe0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionUV1, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS);
				half3 probe0sample = DecodeHDR(probe0, unity_SpecCube0_HDR);

				float3 indirectSpecular;
				float interpolator = unity_SpecCube0_BoxMin.w;
				
				UNITY_BRANCH
				if (interpolator < 0.99999) {
					float3 reflectionUV2 = getReflectionUV(reflDir, i.worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
					half4 probe1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, reflectionUV2, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS);
					half3 probe1sample = DecodeHDR(probe1, unity_SpecCube1_HDR);
					indirectSpecular = lerp(probe1sample, probe0sample, interpolator);
				}
				else {
					indirectSpecular = probe0sample;
				}

				if (any(indirectSpecular) < 0.1)
				{
					indirectSpecular = texCUBElod(_BakedCubemap, float4(reflDir, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS)) * lightAvg;
				}

				half3 metallicColor = indirectSpecular * lerp(0.05,i.diffuseColor.rgb, metallicSmoothness.x);
				spec = lerp(indirectSpecular, metallicColor, pow(d.vdn, 0.05));
			}
			else if(_ReflectionMode == 1) //Baked Cubemap
			{	
				half3 indirectSpecular = texCUBElod(_BakedCubemap, float4(reflDir, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS));;
				half3 metallicColor = indirectSpecular * lerp(0.05,i.diffuseColor.rgb, metallicSmoothness.x);
				spec = lerp(indirectSpecular, metallicColor, pow(d.vdn, 0.05));
				spec *= min(lightAvg,1);
			}
			else if (_ReflectionMode == 2) //Matcap
			{	
				float3 upVector = float3(0,1,0);
				float2 remapUV = matcapSample(upVector, viewDir, i.normal);
				spec = tex2Dlod(_Matcap, float4(remapUV, 0, (metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS)));
				spec *= min(lightAvg,1);
			}
			spec = lerp(spec, spec * ramp, metallicSmoothness.w); // should only not see shadows on a perfect mirror.
			spec *= i.reflectivityMask.r;
		#endif
	return spec;
}

half4 calcOutlineColor(XSLighting i, DotProducts d, float3 indirectDiffuse, float4 lightCol)
{
	float3 outlineColor = _OutlineColor * saturate(i.attenuation * d.ndl) * lightCol.xyz;
	outlineColor += indirectDiffuse * _OutlineColor;

	return float4(outlineColor,1);
}

half4 calcRamp(XSLighting i, DotProducts d)
{
	//d.ndl = saturate(d.ndl);
	half remapRamp; 
	remapRamp = d.ndl * 0.5 + 0.5;

	half4 ramp = tex2D( _Ramp, float2(remapRamp, remapRamp) );
	
	return ramp;
}

half3 calcIndirectDiffuse()
{
	return ShadeSH9(float4(0, 0, 0, 1)); // We don't care about anything other than the color from GI, so only feed in 0,0,0, rather than the normal
}

half4 calcDiffuse(XSLighting i, DotProducts d, float3 indirectDiffuse, float4 lightCol, float4 ramp) 
{	
	float4 diffuse; 
	half4 indirect = indirectDiffuse.xyzz;
	diffuse = ramp * i.attenuation * lightCol + indirect;
	return i.albedo * diffuse;
}

//Subsurface Scattering - Based on a 2011 GDC Conference from by Colin Barre-Bresebois & Marc Bouchard
//Modified by Xiexe
float4 calcSubsurfaceScattering(XSLighting i, DotProducts d, float3 lightDir, float3 viewDir, float3 normal, float4 lightCol, float3 indirectDiffuse)
{	
	d.ndl = smoothstep(_SSSRange - _SSSSharpness, _SSSRange + _SSSSharpness, d.ndl);
	float attenuation = saturate(i.attenuation * d.ndl);
	float3 H = normalize(lightDir + normal * _SSDistortion);
	float VdotH = pow(saturate(dot(viewDir, -H)), _SSPower);
	float3 I = _SSColor * (VdotH + indirectDiffuse) * attenuation * i.thickness * _SSScale;
	float4 SSS = float4(lightCol.rgb * I * i.albedo.rgb, 1);
	SSS = max(0, SSS); // Make sure it doesn't go NaN

	return SSS;
}
//