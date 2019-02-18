
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

void calcNormal(inout XSLighting i)
{
	half3 nMap = UnpackNormal(i.normalMap);
	nMap.xy *= _BumpScale;
	half3 calcedNormal = half3( i.bitangent * nMap.r + 
								i.tangent * nMap.g +
								i.normal * nMap.b  );

	calcedNormal = normalize(calcedNormal);
	half3 bumpedTangent = (cross(i.bitangent, calcedNormal));
    half3 bumpedBitangent = (cross(calcedNormal, bumpedTangent));
	
	i.normal = calcedNormal;
	i.tangent = bumpedTangent;
	i.bitangent = bumpedBitangent;
}

void InitializeTextureUVs(
	#if defined(Geometry)
		in g2f i,
	#else
		in VertexOutput i, 
	#endif
		inout TextureUV t)
{	
	half2 uvSetAlbedo = (_UVSetAlbedo == 0) ? i.uv : i.uv1;
	half2 uvSetNormalMap = (_UVSetNormal == 0) ? i.uv : i.uv1;
	half2 uvSetDetailNormal = (_UVSetDetNormal == 0) ? i.uv : i.uv1;
	half2 uvSetDetailMask = (_UVSetDetMask == 0) ? i.uv : i.uv1;
	half2 uvSetMetallicGlossMap = (_UVSetMetallic == 0) ? i.uv : i.uv1;
	half2 uvSetSpecularMap = (_UVSetSpecular == 0) ? i.uv : i.uv1;

	t.albedoUV = TRANSFORM_TEX(uvSetAlbedo, _MainTex);
	t.normalMapUV = TRANSFORM_TEX(uvSetNormalMap, _BumpMap);
	t.detailNormalUV = TRANSFORM_TEX(uvSetDetailNormal, _DetailNormalMap);
	t.detailMaskUV = TRANSFORM_TEX(uvSetDetailMask, _DetailMask);
	t.metallicGlossMapUV = TRANSFORM_TEX(uvSetMetallicGlossMap, _SpecularMap);
	t.specularMapUV = TRANSFORM_TEX(uvSetSpecularMap, _MetallicGlossMap);
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

half3 calcLightDir(half3 worldPos, int lightEnv)
{
	half3 lightDir = UnityWorldSpaceLightDir(worldPos);

    if(lightEnv != 1)
    {
        lightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz; // Get light direction from light probes if there is no Directional Light.

		#if !defined(POINT) && !defined(SPOT)
			if(length(unity_SHAr.xyz*unity_SHAr.w + unity_SHAg.xyz*unity_SHAg.w + unity_SHAb.xyz*unity_SHAb.w) == 0)
			{
				lightDir = float4(1, 1, 1, 0);
			}
		#endif
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

half4 calcRimLight(XSLighting i, DotProducts d, half4 lightCol, half3 indirectDiffuse)
{	
	half rimIntensity = saturate((1-d.vdn) * pow(d.ndl, _RimThreshold));
	rimIntensity = smoothstep(_RimRange - 0.01, _RimRange + 0.01, rimIntensity);
	half4 rim = (rimIntensity * _RimIntensity * (lightCol + indirectDiffuse.xyzz) * i.albedo * i.attenuation);
	
	return rim;
}

half4 calcShadowRim(XSLighting i, DotProducts d, half3 indirectDiffuse)
{
	half rimIntensity = saturate((1-d.vdn) * pow(-d.ndl, _ShadowRimThreshold * 2));
	rimIntensity = smoothstep(_ShadowRimRange - 0.3, _ShadowRimRange + 0.3, rimIntensity);
	
	half4 shadowRim = lerp(1, _ShadowRim + (indirectDiffuse.xyzz * _ShadowColor * 0.1), rimIntensity);

	return shadowRim;
}

//Direct Lighting Fuctions
	// From HDRenderPipeline
	float D_GGXAnisotropic(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
	{
		float f = TdotH * TdotH / (roughnessT * roughnessT) + BdotH * BdotH / (roughnessB * roughnessB) + NdotH * NdotH;
		return 1.0 / (roughnessT * roughnessB * f * f);
	}

	half3 calcDirectSpecular(XSLighting i, DotProducts d, half4 lightCol, half3 indirectDiffuse, half2 metallicSmoothness, half ax, half ay)
	{	
		lightCol = (lightCol + indirectDiffuse.xyzz) * i.albedo;
		float specularIntensity = _SpecularIntensity * i.specularMap.r;
		if(_SpecMode == 0)
		{
			half3 reflectionUntouched = saturate(pow(d.rdv, _SpecularArea * 128));
			float specular = lerp(reflectionUntouched, round(reflectionUntouched), _SpecularStyle) * specularIntensity * lightCol;
			return specular * i.attenuation;
		}
		else if(_SpecMode == 1)
		{
			half smooth = saturate(D_GGXAnisotropic(d.tdh, d.bdh, d.ndh, ax, ay));
			half sharp = round(smooth) * 2 * 0.5;
			float specular = lerp(smooth, sharp, _SpecularStyle) * lightCol * specularIntensity;
			return specular * i.attenuation;
		}
		else
		{
			float sndl = saturate(d.ndl);	
			float roughness = 1-(_SpecularArea);
			float V = SmithJointGGXVisibilityTerm(sndl, d.vdn, roughness);
			float F = F_Schlick(float3(0.0, 0.0, 0.0), d.ldh);
			float D = XSGGXTerm(d.ndh, roughness*roughness);

			float reflection = V * D * UNITY_PI;
			float smooth = (max(0, reflection * sndl) * F * i.attenuation) * lightCol * specularIntensity;
			float sharp = round(smooth);
			float specular = lerp(smooth, sharp, _SpecularStyle);
			return specular * i.attenuation;
		}
	}
//----

//Indirect Lighting functions
	half3 calcIndirectDiffuse()
	{
		return ShadeSH9(float4(0, 0, 0, 1)); //Just get the Lightprobe Color information
	}

	half3 calcIndirectSpecular(XSLighting i, float2 metallicSmoothness, half3 reflDir)
	{	
		half4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, metallicSmoothness.y * UNITY_SPECCUBE_LOD_STEPS);
		half3 indirectSpecular = DecodeHDR(envSample, unity_SpecCube0_HDR);
		half3 indirectLighting = indirectSpecular * i.albedo * metallicSmoothness.x;
		#if !defined(DIRECTIONAL)
			indirectLighting *= i.attenuation;
		#endif

		return indirectLighting;
	}
//----

	half4 calcOutlineColor(XSLighting i, DotProducts d, float3 indirectDiffuse, float4 lightCol)
	{
		float3 outlineColor = _OutlineColor * i.attenuation * d.ndl * lightCol.xyz;
		outlineColor += indirectDiffuse * _OutlineColor;

		return float4(outlineColor,1);
	}

//Ramp
	half4 calcRamp(XSLighting i, DotProducts d)
	{
		half remapRamp; 
        remapRamp = d.ndl * 0.5 + 0.5;

        half4 ramp = tex2D( _Ramp, float2(remapRamp, remapRamp) );
        
        return ramp;
	}

	half4 calcDiffuse(XSLighting i, DotProducts d, float3 indirectDiffuse, float4 lightCol, int lightEnv) 
	{	
		float4 diffuse; 
		//I treat the indirect color as the light color if there's no Main Directional Light (This only happens in the forward base pass). 
		//mult by 0.2 to make it slightly more appealing visually (Makes the shadows lighter and less overbearing).
		if(lightEnv != 1)
			lightCol = indirectDiffuse.xyzz * 0.2; 

		UNITY_BRANCH
		if(_RampMode != 2)
		{	
			//Modify ndl to make the shadow ramp "wrap" around the attenuation if being lit by a directional light.
			//I prefer this look only on directional lights, as it slightly obscures the attenuation.
			//Whereas on Point and Spot lights, it looks a lot worse.
			#if defined(DIRECTIONAL)
				d.ndl *= i.attenuation;
			#endif
			half4 ramp = calcRamp(i, d);
			half lightAvg = (lightCol.r + lightCol.g + lightCol.b) * 0.33333;
			half indirectAvg = (indirectDiffuse.r + indirectDiffuse.g + indirectDiffuse.b) * 0.33333;
			
			UNITY_BRANCH
			if (_RampMode == 0) // Mixed
				diffuse = (ramp * lightCol) + indirectDiffuse.xyzz;
			else // Ramp
				diffuse = (ramp * lightAvg) + indirectAvg;

			diffuse *= i.attenuation + indirectDiffuse.xyzz;
		}
		else
		{	
			d.ndl = smoothstep(_ShadowRange - _ShadowSharpness, _ShadowRange + _ShadowSharpness, d.ndl);
			half altNDL = d.ndl * i.attenuation; 
			altNDL = (ceil(altNDL * _ShadowSteps) / _ShadowSteps); 
			diffuse = altNDL * lightCol;
			#if defined(POINT) || defined(SPOT)
				diffuse *= i.attenuation;
			#endif
			diffuse += (indirectDiffuse.rgbb * _ShadowColor);
		}
		return i.albedo * diffuse;
	}

	void calcAlpha(inout XSLighting i)
	{	
		//Default to 1 alpha || Opaque
		i.alpha = 1;

		// #if defined(AlphaToMask)
		// 	i.alpha = i.albedo.a;
		// #endif

		#if defined(AlphaBlend) || defined(AlphaToMask)
			i.alpha = i.albedo.a;
		#endif

		#if defined(Cutout)
			clip(i.albedo.a - _Cutoff);
		#endif
	}
//----
