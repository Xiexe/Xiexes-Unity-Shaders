//Half tone functions
float2 calcScreenUVs(float4 screenPos, float distanceToObjectOrigin, float3 viewDir, float3 worldPos)
{
	float2 clipPos = screenPos / (screenPos.w + 0.0000000001);
	float2 uv = 2*clipPos-1;

	#if UNITY_SINGLE_PASS_STEREO
		uv.x *= (_ScreenParams.x * 2) / _ScreenParams.y;
	#else
		uv.x *= (_ScreenParams.x) / _ScreenParams.y;
	#endif
	uv *= distanceToObjectOrigin;
	return uv;
}

float2 rotateUV(float2 uv, float rotation)
{
    float mid = 0.5;
    return float2(
        cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
        cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

float DotHalftone(XSLighting i, float scalar) //Scalar can be anything from attenuation to a dot product
{
	float2 uv = i.screenUV;
	#if UNITY_SINGLE_PASS_STEREO
		uv *= 2.5;
	#endif
	
    float2 nearest = 2 * frac(_HalftoneDotAmount * uv) - 1;
    float dist = length(nearest);
	float dotSize = _HalftoneDotSize * scalar;
    float dotMask = step(dotSize, dist);

	return dotMask;
}

float LineHalftone(XSLighting i, float scalar)
{	
	// #if defined(DIRECTIONAL)
	// 	scalar = saturate(scalar + ((1-i.attenuation) * 0.2));
	// #endif
	float2 uv = i.screenUV;
	uv = rotateUV(uv, -0.785398);
	#if UNITY_SINGLE_PASS_STEREO
		_HalftoneLineAmount = _HalftoneLineAmount * 2.5;
	#endif
	uv.x = sin(uv.x * _HalftoneLineAmount);

	float2 steppedUV = smoothstep(0,0.2,uv.x);
	float lineMask = steppedUV * 0.2 * scalar;

	return saturate(lineMask);
}
//

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
	half2 uvSetThickness = (_UVSetThickness == 0) ? i.uv : i.uv1;

	t.albedoUV = TRANSFORM_TEX(uvSetAlbedo, _MainTex);
	t.normalMapUV = TRANSFORM_TEX(uvSetNormalMap, _BumpMap);
	t.detailNormalUV = TRANSFORM_TEX(uvSetDetailNormal, _DetailNormalMap);
	t.detailMaskUV = TRANSFORM_TEX(uvSetDetailMask, _DetailMask);
	t.metallicGlossMapUV = TRANSFORM_TEX(uvSetMetallicGlossMap, _SpecularMap);
	t.specularMapUV = TRANSFORM_TEX(uvSetSpecularMap, _MetallicGlossMap);
	t.thicknessMapUV = TRANSFORM_TEX(uvSetSpecularMap, _ThicknessMap);
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

// Get the most intense light Dir from probes OR from a light source. Method developed by Xiexe / Merlin
half3 calcLightDir(XSLighting i)
{
	half3 lightDir = UnityWorldSpaceLightDir(i.worldPos);
	lightDir *= i.attenuation * dot(_LightColor0, grayscaleVec);

	half3 probeLightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
	lightDir = (lightDir + probeLightDir) / 2;

		#if !defined(POINT) && !defined(SPOT)
			if(length(unity_SHAr.xyz*unity_SHAr.w + unity_SHAg.xyz*unity_SHAg.w + unity_SHAb.xyz*unity_SHAb.w) == 0)
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
	rimIntensity = smoothstep(_RimRange - _RimSharpness, _RimRange + _RimSharpness, rimIntensity);
	half4 rim = (rimIntensity * _RimIntensity * (lightCol + indirectDiffuse.xyzz) * i.albedo * i.attenuation);
	float dotHalftone = 1-DotHalftone(i, rimIntensity);
	rim *= dotHalftone;
	
	return rim;
}

half4 calcShadowRim(XSLighting i, DotProducts d, half3 indirectDiffuse)
{
	half rimIntensity = saturate((1-d.vdn) * pow(-d.ndl, _ShadowRimThreshold * 2));
	rimIntensity = smoothstep(_ShadowRimRange - _ShadowRimSharpness, _ShadowRimRange + _ShadowRimSharpness, rimIntensity);
	half4 shadowRim = lerp(1, _ShadowRim + (indirectDiffuse.xyzz * _ShadowColor * 0.1), rimIntensity);

	return shadowRim;
}

//Direct Lighting Fuctions
	// From HDRenderPipeline
	float D_GGXAnisotropic(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
	{	
		float f = TdotH * TdotH / (roughnessT * roughnessT) + BdotH * BdotH / (roughnessB * roughnessB) + NdotH * NdotH;
		float aniso = 1.0 / (roughnessT * roughnessB * f * f);
		return aniso;
	}

	half3 calcDirectSpecular(XSLighting i, DotProducts d, half4 lightCol, half3 indirectDiffuse, half2 metallicSmoothness, half ax, half ay)
	{	
		lightCol = (lightCol + indirectDiffuse.xyzz) * i.albedo;
		float specularIntensity = _SpecularIntensity * i.specularMap.r;

		if(_SpecMode == 0)
		{
			half reflectionUntouched = saturate(pow(d.rdv, _SpecularArea * 128));
			float dotHalftone = 1-DotHalftone(i, reflectionUntouched);
			float specular = lerp(reflectionUntouched, round(reflectionUntouched), _SpecularStyle) * specularIntensity * lightCol * (_SpecularArea * 2) * i.albedo * dotHalftone;
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
		return ShadeSH9(float4(0, 0, 0, 1)); // We don't care about anything other than the color from GI, so only feed in 0,0,0, rather than the normal
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
		float3 outlineColor = _OutlineColor * saturate(i.attenuation * d.ndl) * lightCol.xyz;
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

	half4 calcDiffuse(XSLighting i, DotProducts d, float3 indirectDiffuse, float4 lightCol) 
	{	
		float4 diffuse; 
			half4 ramp = calcRamp(i, d);
			half lightAvg = (lightCol.r + lightCol.g + lightCol.b) * 0.33333;
			half indirectAvg = (indirectDiffuse.r + indirectDiffuse.g + indirectDiffuse.b) * 0.33333;
			
			UNITY_BRANCH
			if (_RampMode == 0) // Mixed
				diffuse = (ramp * lightCol) + indirectDiffuse.xyzz;
			else // Ramp
				diffuse = (ramp * lightAvg) + indirectAvg;

			diffuse *= i.attenuation + (indirectDiffuse.xyzz * _ShadowColor);

		return i.albedo * diffuse;
	}

	void calcAlpha(inout XSLighting i)
	{	
		//Default to 1 alpha || Opaque
		i.alpha = 1;

		#if defined(AlphaBlend) || defined(AlphaToMask)
			i.alpha = i.albedo.a;
		#endif

		#if defined(Cutout)
			clip(i.albedo.a - _Cutoff);
		#endif
	}
//----

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

