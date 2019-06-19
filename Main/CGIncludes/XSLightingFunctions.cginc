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
    
    half3 F_Schlick(half3 SpecularColor, half VoH)
    {
        return SpecularColor + (1.0 - SpecularColor) * exp2((-5.55473 * VoH) - (6.98316 * VoH));
    }

    // From HDRenderPipeline
    half D_GGXAnisotropic(half TdotH, half BdotH, half NdotH, half roughnessT, half roughnessB)
    {	
        half f = TdotH * TdotH / (roughnessT * roughnessT) + BdotH * BdotH / (roughnessB * roughnessB) + NdotH * NdotH;
        half aniso = 1.0 / (roughnessT * roughnessB * f * f);
        return aniso;
    }

    half3 calcReflView(half3 viewDir, half3 normal)
    {
        return reflect(-viewDir, normal);
    }
    
    half3 calcReflLight(half3 lightDir, half3 normal)
    {
        return reflect(lightDir, normal);
    }
//

half3 getVertexLightsDir(XSLighting i)
{
    half3 toLightX = half3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
    half3 toLightY = half3(unity_4LightPosX0.y, unity_4LightPosY0.y, unity_4LightPosZ0.y);
    half3 toLightZ = half3(unity_4LightPosX0.z, unity_4LightPosY0.z, unity_4LightPosZ0.z);
    half3 toLightW = half3(unity_4LightPosX0.w, unity_4LightPosY0.w, unity_4LightPosZ0.w);

    half3 dirX = toLightX - i.worldPos;
    half3 dirY = toLightY - i.worldPos;
    half3 dirZ = toLightZ - i.worldPos;
    half3 dirW = toLightW - i.worldPos;
    
    dirX *= length(toLightX);
    dirY *= length(toLightY);
    dirZ *= length(toLightZ);
    dirW *= length(toLightW);

    half3 dir = (dirX + dirY + dirZ + dirW);
    return normalize(dir); //Has to be normalized before feeding into LightDir, otherwise you end up with some weird behavior.
}

// Get the most intense light Dir from probes OR from a light source. Method developed by Xiexe / Merlin
half3 calcLightDir(XSLighting i)
{   
    half3 lightDir = UnityWorldSpaceLightDir(i.worldPos);

    half3 probeLightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
    lightDir = (lightDir + probeLightDir); //Make light dir the average of the probe direction and the light source direction.
    
    #if defined(VERTEXLIGHT_ON)
        half3 vertexDir = getVertexLightsDir(i);
        lightDir = (lightDir + probeLightDir + vertexDir);
    #endif

    #if !defined(POINT) && !defined(SPOT) && !defined(VERTEXLIGHT_ON) // if the average length of the light probes is null, and we don't have a directional light in the scene, fall back to our fallback lightDir
        if(length(unity_SHAr.xyz*unity_SHAr.w + unity_SHAg.xyz*unity_SHAg.w + unity_SHAb.xyz*unity_SHAb.w) == 0 && length(lightDir) < 0.1)
        {
            lightDir = half4(1, 1, 1, 0);
        }
    #endif

    return normalize(lightDir);
}

void calcLightCol(bool lightEnv, inout half3 indirectDiffuse, inout half4 lightColor)
{
    //If we're in an environment with a realtime light, then we should use the light color, and indirect color raw.
    //Otherwise, we can use the raw indirect color as the light color, and halve if for the indirect color. 
    //This produces a result that looks very similar to realtime lighting.
    if(lightEnv)
    {
        lightColor = _LightColor0;
        indirectDiffuse = indirectDiffuse;
    }
    else
    {
        lightColor = indirectDiffuse.xyzz;
        indirectDiffuse = indirectDiffuse * 0.5;
    }
}

half3 get4VertexLightsColFalloff(half3 worldPos, half3 normal)
{
    half3 lightColor = 0;
    half4 toLightX = unity_4LightPosX0 - worldPos.x;
    half4 toLightY = unity_4LightPosY0 - worldPos.y;
    half4 toLightZ = unity_4LightPosZ0 - worldPos.z;

    half4 lengthSq = 0;
    lengthSq += toLightX * toLightX;
    lengthSq += toLightY * toLightY;
    lengthSq += toLightZ * toLightZ;

    half4 atten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);
    atten = atten*atten; // Cleaner, nicer looking falloff. Also prevents the "Snapping in" effect that Unity's normal integration of vertex lights has.
    
    lightColor.rgb += unity_LightColor[0] * atten.x;
    lightColor.rgb += unity_LightColor[1] * atten.y;
    lightColor.rgb += unity_LightColor[2] * atten.z;
    lightColor.rgb += unity_LightColor[3] * atten.w;

    return lightColor;
}

half4 calcMetallicSmoothness(XSLighting i)
{
    half roughness = 1-(_Glossiness * i.metallicGlossMap.a);
    roughness *= 1.7 - 0.7 * roughness;
    half metallic = lerp(0, i.metallicGlossMap.r * _Metallic, i.reflectivityMask.r);
    return half4(metallic, 0, 0, roughness);
}

half4 calcRimLight(XSLighting i, DotProducts d, half4 lightCol, half3 indirectDiffuse)
{
    half rimIntensity = saturate((1-d.svdn)) * pow(d.ndl, _RimThreshold);
    rimIntensity = smoothstep(_RimRange - _RimSharpness, _RimRange + _RimSharpness, rimIntensity);
    half4 rim = rimIntensity * _RimIntensity * (lightCol + indirectDiffuse.xyzz);
    #if !defined(UNITY_PASS_FORWARDBASE)
        rim *= i.attenuation;
    #endif
    return rim * _RimColor * i.diffuseColor.xyzz;
}

half4 calcShadowRim(XSLighting i, DotProducts d, half3 indirectDiffuse)
{
    half rimIntensity = saturate((1-d.svdn)) * pow(1-d.ndl, _ShadowRimThreshold * 2);
    rimIntensity = smoothstep(_ShadowRimRange - _ShadowRimSharpness, _ShadowRimRange + _ShadowRimSharpness, rimIntensity);
    half4 shadowRim = lerp(1, _ShadowRim + (indirectDiffuse.xyzz * 0.1), rimIntensity);

    return shadowRim;
}

half3 calcDirectSpecular(XSLighting i, DotProducts d, half4 lightCol, half3 indirectDiffuse, half4 metallicSmoothness, half ax, half ay)
{
    half specularIntensity = _SpecularIntensity * i.specularMap.r;
    half3 specular = half3(0,0,0);
    half smoothness = max(0.01, (_SpecularArea * i.specularMap.b));
    smoothness *= 1.7 - 0.7 * smoothness;
    
    if(_SpecMode == 0)
    {
        half reflectionUntouched = saturate(pow(d.rdv, smoothness * 128));
        specular = lerp(reflectionUntouched, round(reflectionUntouched), _SpecularStyle) * specularIntensity * (_SpecularArea + 0.5);
    }
    else if(_SpecMode == 1)
    {
        half smooth = saturate(D_GGXAnisotropic(d.tdh, d.bdh, d.ndh, ax, ay));
        half sharp = round(smooth) * 2 * 0.5;
        specular = lerp(smooth, sharp, _SpecularStyle) * specularIntensity;
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
    specular *= i.attenuation * lightCol;
    half3 tintedAlbedoSpecular = specular * i.diffuseColor;
    specular = lerp(specular, tintedAlbedoSpecular, _SpecularAlbedoTint * i.specularMap.g); // Should specular highlight be tinted based on the albedo of the object?
    return specular;
}

half3 calcIndirectSpecular(XSLighting i, DotProducts d, half4 metallicSmoothness, half3 reflDir, half3 indirectLight, half3 viewDir, half4 ramp)
{//This function handls Unity style reflections, Matcaps, and a baked in fallback cubemap.
        half3 spec = half3(0,0,0);

        UNITY_BRANCH
        if(_ReflectionMode == 0) // PBR
        {
            #if defined(UNITY_PASS_FORWARDBASE) //Indirect PBR specular should only happen in the forward base pass. Otherwise each extra light adds another indirect sample, which could mean you're getting too much light. 
                half3 reflectionUV1 = getReflectionUV(reflDir, i.worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
                half4 probe0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionUV1, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS);
                half3 probe0sample = DecodeHDR(probe0, unity_SpecCube0_HDR);

                half3 indirectSpecular;
                half interpolator = unity_SpecCube0_BoxMin.w;
                
                UNITY_BRANCH
                if (interpolator < 0.99999) 
                {
                    half3 reflectionUV2 = getReflectionUV(reflDir, i.worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
                    half4 probe1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, reflectionUV2, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS);
                    half3 probe1sample = DecodeHDR(probe1, unity_SpecCube1_HDR);
                    indirectSpecular = lerp(probe1sample, probe0sample, interpolator);
                }
                else 
                {
                    indirectSpecular = probe0sample;
                }

                if (!any(indirectSpecular))
                {
                    indirectSpecular = texCUBElod(_BakedCubemap, half4(reflDir, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS));
                    indirectSpecular *= indirectLight;
                }

                half3 metallicColor = indirectSpecular * lerp(0.05,i.diffuseColor.rgb, metallicSmoothness.x);
                spec = lerp(indirectSpecular, metallicColor, pow(d.vdn, 0.05));
            #endif
        }
        else if(_ReflectionMode == 1) //Baked Cubemap
        {
            half3 indirectSpecular = texCUBElod(_BakedCubemap, half4(reflDir, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS));;
            half3 metallicColor = indirectSpecular * lerp(0.1,i.diffuseColor.rgb, metallicSmoothness.x);
            spec = lerp(indirectSpecular, metallicColor, pow(d.vdn, 0.05));
            
            if(_ReflectionBlendMode != 1)
            {
                spec *= indirectLight;
            }
        }
        else if (_ReflectionMode == 2) //Matcap
        {
            half3 upVector = half3(0,1,0);
            half2 remapUV = matcapSample(upVector, viewDir, i.normal);
            spec = tex2Dlod(_Matcap, half4(remapUV, 0, ((1-metallicSmoothness.w) * UNITY_SPECCUBE_LOD_STEPS))) * _MatcapTint;
            
            if(_ReflectionBlendMode != 1)
            {
                spec *= indirectLight;
            }
        }
        spec = lerp(spec, spec * ramp, metallicSmoothness.w); // should only not see shadows on a perfect mirror.
    return spec;
}

half4 calcOutlineColor(XSLighting i, DotProducts d, half3 indirectDiffuse, half4 lightCol)
{
    half3 outlineColor = half3(0,0,0);
    #if defined(Geometry)
        outlineColor = _OutlineColor * saturate(i.attenuation * d.ndl) * lightCol.xyz;
        outlineColor += indirectDiffuse * _OutlineColor;
    #endif

    return half4(outlineColor,1);
}

half4 calcRamp(XSLighting i, DotProducts d)
{
    half remapRamp; 
    remapRamp = d.ndl * 0.5 + 0.5;

    half4 ramp = tex2D( _Ramp, half2(remapRamp, i.rampMask.r) );

    return ramp;
}

half3 calcIndirectDiffuse()
{// We don't care about anything other than the color from probes for toon lighting.
    half3 indirectDiffuse = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    return indirectDiffuse;
}

half4 calcDiffuse(XSLighting i, DotProducts d, half3 indirectDiffuse, half4 lightCol, half4 ramp) 
{
    half4 diffuse; 
    half4 indirect = indirectDiffuse.xyzz;
    diffuse = ramp * i.attenuation * lightCol + indirect;
    diffuse = i.albedo * diffuse;
    return diffuse;
}

//Subsurface Scattering - Based on a 2011 GDC Conference from by Colin Barre-Bresebois & Marc Bouchard
//Modified by Xiexe
half4 calcSubsurfaceScattering(XSLighting i, DotProducts d, half3 lightDir, half3 viewDir, half3 normal, half4 lightCol, half3 indirectDiffuse)
{
    UNITY_BRANCH
    if(any(_SSColor.rgb)) // Skip all the SSS stuff if the color is 0.
    {
        d.ndl = smoothstep(_SSSRange - _SSSSharpness, _SSSRange + _SSSSharpness, d.ndl);
        half attenuation = saturate(i.attenuation * d.ndl);
        half3 H = normalize(lightDir + normal * _SSDistortion);
        half VdotH = pow(saturate(dot(viewDir, -H)), _SSPower);
        half3 I = _SSColor * (VdotH + indirectDiffuse) * attenuation * i.thickness * _SSScale;
        half4 SSS = half4(lightCol.rgb * I * i.albedo.rgb, 1);
        SSS = max(0, SSS); // Make sure it doesn't go NaN

        return SSS;
    }
    else
    {
        return 0;
    }
}

half4 calcEmission(XSLighting i, half lightAvg)
{
    #if defined(UNITY_PASS_FORWARDBASE) // Emission only in Base Pass, and vertex lights
        half4 emission = lerp(i.emissionMap, i.emissionMap * i.diffuseColor.xyzz, _EmissionToDiffuse);
        half4 scaledEmission = emission * saturate(smoothstep(1-_ScaleWithLightSensitivity, 1+_ScaleWithLightSensitivity, 1-lightAvg));

        return lerp(scaledEmission, emission, _ScaleWithLight);
    #else 
        return 0;
    #endif
}

void calcReflectionBlending(XSLighting i, inout half4 col, half3 indirectSpecular)
{
    if(_ReflectionBlendMode == 0) // Additive
        col += indirectSpecular.xyzz * i.reflectivityMask.r;
    else if(_ReflectionBlendMode == 1) //Multiplicitive
        col = lerp(col, col * indirectSpecular.xyzz, i.reflectivityMask.r);
    else if(_ReflectionBlendMode == 2) //Subtractive
        col -= indirectSpecular.xyzz * i.reflectivityMask.r;
}

void calcClearcoat(inout half4 col, XSLighting i, DotProducts d, half3 untouchedNormal, half3 indirectDiffuse, half3 lightCol, half3 viewDir, half3 lightDir, half4 ramp)
{
    UNITY_BRANCH
    if(_ClearCoat != 0)
    {
        untouchedNormal = normalize(untouchedNormal);
        half clearcoatSmoothness = _ClearcoatSmoothness * i.metallicGlossMap.g;
        half clearcoatStrength = _ClearcoatStrength * i.metallicGlossMap.b;
        
        half3 reflView = calcReflView(viewDir, untouchedNormal);
        half3 reflLight = calcReflLight(lightDir, untouchedNormal);
        half rdv = saturate( dot( reflLight, half4(-viewDir, 0) ));
        half3 clearcoatIndirect = calcIndirectSpecular(i, d, half4(0, 0, 0, 1-clearcoatSmoothness), reflView, indirectDiffuse, viewDir, ramp);
        half3 clearcoatDirect = saturate(pow(rdv, clearcoatSmoothness * 256)) * i.attenuation * lightCol;

        half3 clearcoat = (clearcoatIndirect + clearcoatDirect) * clearcoatStrength;
        clearcoat = lerp(clearcoat * 0.5, clearcoat, saturate(pow(1-dot(viewDir, untouchedNormal), 0.8)) );
        col += clearcoat.xyzz;
    }
}
