//Helper Functions for Reflections
float pow5(float a)
{
    return a * a * a * a * a;
}

float3 F_Schlick(float u, float3 f0)
{
    return f0 + (1.0 - f0) * pow(1.0 - u, 5.0);
}

float3 F_FresnelLerp (float3 F0, float3 F90, float cosA)
{
    float t = pow5(1 - cosA);   // ala Schlick interpoliation
    return lerp (F0, F90, t);
}

float D_GGX(float NoH, float roughness)
{
    float a2 = roughness * roughness;
    float f = (NoH * a2 - NoH) * NoH + 1.0;
    return a2 / (UNITY_PI * f * f);
}

float D_GGX_Anisotropic(float NoH, const float3 h, const float3 t, const float3 b, float at, float ab)
{
    float ToH = dot(t, h);
    float BoH = dot(b, h);
    float a2 = at * ab;
    float3 v = float3(ab * ToH, at * BoH, a2 * NoH);
    float v2 = dot(v, v);
    float w2 = a2 / v2;
    return a2 * w2 * w2 * (1.0 / UNITY_PI);
}

float V_SmithGGXCorrelated(float NoV, float NoL, float a)
{
    float a2 = a * a;
    float GGXL = NoV * sqrt((-NoL * a2 + NoL) * NoL + a2);
    float GGXV = NoL * sqrt((-NoV * a2 + NoV) * NoV + a2);
    return 0.5 / (GGXV + GGXL);
}

half3 calcReflView(half3 viewDir, half3 normal)
{
    return reflect(-viewDir, normal);
}

half4 calcMetallicSmoothness(FragmentData i)
{
    half roughness = 1-(_Glossiness * i.metallicGlossMap.a);
    roughness *= 1.7 - 0.7 * roughness;
    half metallic = i.metallicGlossMap.r * _Metallic;
    return half4(metallic, 0, 0, roughness);
}

// half4 calcRimLight(FragmentData i, DotProducts d, half4 lightCol, half3 indirectDiffuse, half3 envMap)
// {
//     half rimIntensity = saturate((1-d.svdn)) * pow(d.ndl, _RimThreshold);
//     rimIntensity = smoothstep(_RimRange - _RimSharpness, _RimRange + _RimSharpness, rimIntensity);
//     half4 rim = rimIntensity * _RimIntensity * (lightCol + indirectDiffuse.xyzz);
//     rim *= lerp(1, i.attenuation + indirectDiffuse.xyzz, _RimAttenEffect);
//
//     half4 rimLight = rim * _RimColor * lerp(1, i.diffuseColor.rgbb, _RimAlbedoTint) * lerp(1, envMap.rgbb, _RimCubemapTint);
//     return lerp(0, rimLight, i.rimMask.r);
// }
//
// half4 calcShadowRim(FragmentData i, DotProducts d, half3 indirectDiffuse)
// {
//     half rimIntensity = saturate((1-d.svdn)) * pow(1-d.ndl, _ShadowRimThreshold * 2);
//     rimIntensity = smoothstep(_ShadowRimRange - _ShadowRimSharpness, _ShadowRimRange + _ShadowRimSharpness, rimIntensity);
//     half4 shadowRim = lerp(1, (_ShadowRim * lerp(1, i.diffuseColor.rgbb, _ShadowRimAlbedoTint)) + (indirectDiffuse.xyzz * 0.1), rimIntensity);
//
//     return lerp(1, shadowRim, i.rimMask.g);
// }

float3 getAnisotropicReflectionVector(float3 viewDir, float3 bitangent, float3 tangent, float3 normal, float roughness, float anisotropy)
{
    //_Anisotropy = lerp(-0.2, 0.2, sin(_Time.y / 20)); //This is pretty fun
    float3 anisotropicDirection = anisotropy >= 0.0 ? bitangent : tangent;
    float3 anisotropicTangent = cross(anisotropicDirection, viewDir);
    float3 anisotropicNormal = cross(anisotropicTangent, anisotropicDirection);
    float bendFactor = abs(anisotropy) * saturate(5.0 * roughness);
    float3 bentNormal = normalize(lerp(normal, anisotropicNormal, bendFactor));
    return reflect(-viewDir, bentNormal);
}

half3 GetDirectSpecular(FragmentData i, DotProducts d, Light light, half anisotropy)
{
    half specularIntensity = _SpecularIntensity * i.specularMap.r;
    half3 specular = half3(0,0,0);
    half smoothness = max(0.01, (_SpecularArea * i.specularMap.b));
    smoothness *= 1.7 - 0.7 * smoothness;

    float rough = max(smoothness * smoothness, 0.0045);
    float Dn = D_GGX(light.ndh, rough);
    float3 F = 1-F_Schlick(light.ldh, 0);
    float V = V_SmithGGXCorrelated(d.vdn, light.ndl, rough);
    float3 directSpecularNonAniso = max(0, (Dn * V) * F);

    anisotropy *= saturate(5.0 * smoothness);
    float at = max(rough * (1.0 + anisotropy), 0.001);
    float ab = max(rough * (1.0 - anisotropy), 0.001);
    float D = D_GGX_Anisotropic(light.ndh, light.halfVector, i.tangent, i.bitangent, at, ab);
    float3 directSpecularAniso = max(0, (D * V) * F);

    specular = lerp(directSpecularNonAniso, directSpecularAniso, saturate(abs(anisotropy * 100)));
    specular = lerp(specular, smoothstep(0.5, 0.51, specular), _SpecularSharpness) * 3 * light.color * specularIntensity; // Multiply by 3 to bring up to brightness of standard
    specular *= lerp(1, i.diffuseColor, _SpecularAlbedoTint * i.specularMap.g);
    return specular;
}

half3 GetIndirectSpecular(FragmentData i, half4 metallicSmoothness, half3 reflDir, half3 indirectLight, half3 viewDir, float3 fresnel)
{//This function handls Unity style reflections, Matcaps, and a baked in fallback cubemap.
    half3 spec = half3(0,0,0);

    UNITY_BRANCH
    if(_ReflectionMode == REFLECTIONMODE_PBR) // PBR
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
            spec = indirectSpecular * fresnel;
        #endif
    }
    else if(_ReflectionMode == REFLECTIONMODE_BAKEDPBR) //Baked Cubemap
    {
        half3 indirectSpecular = texCUBElod(_BakedCubemap, half4(reflDir, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS));;
        spec = indirectSpecular * fresnel;

        if(_ReflectionBlendMode != 1)
        {
            spec *= (indirectLight + (_LightColor0 * i.attenuation) * 0.5);
        }
    }
    else if (_ReflectionMode == REFLECTIONMODE_MATCAP) //Matcap
    {
        half3 upVector = half3(0,1,0);
        half2 remapUV = matcapSample(upVector, viewDir, i.normal);
        spec = tex2Dlod(_Matcap, half4(remapUV, 0, ((1-metallicSmoothness.w) * UNITY_SPECCUBE_LOD_STEPS))) * _MatcapTint;

        if(_ReflectionBlendMode != 1)
        {
            spec *= (indirectLight + (_LightColor0 * i.attenuation) * 0.5);
        }

        spec *= lerp(1, i.diffuseColor, _MatcapTintToDiffuse);
    }
    return spec;
}


float4 getRealtimeLightmap(float2 uv, float3 worldNormal)
{
    float2 realtimeUV = uv * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    float4 bakedCol = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, realtimeUV);
    float3 realtimeLightmap = DecodeRealtimeLightmap(bakedCol);

    #ifdef DIRLIGHTMAP_COMBINED
        float4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, realtimeUV);
        realtimeLightmap += DecodeDirectionalLightmap (realtimeLightmap, realtimeDirTex, worldNormal);
    #endif

    return float4(realtimeLightmap.rgb, 1);
}

float4 getLightmap(float2 uv, float3 worldNormal, float3 worldPos)
{
    float2 lightmapUV = uv * unity_LightmapST.xy + unity_LightmapST.zw;
    float4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, lightmapUV);
    float3 lightMap = DecodeLightmap(bakedColorTex);

    #ifdef DIRLIGHTMAP_COMBINED
        fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, lightmapUV);
        lightMap = DecodeDirectionalLightmap(lightMap, bakedDirTex, worldNormal);
    #endif
    return float4(lightMap.rgb, 1);
}

//Subsurface Scattering - Based on a 2011 GDC Conference from by Colin Barre-Bresebois & Marc Bouchard
//Modified by Xiexe
half4 GetSubsurfaceScattering(FragmentData i, Light light, half3 viewDir, half3 normal, half3 indirectDiffuse)
{
    UNITY_BRANCH
    if(any(_SSColor.rgb)) // Skip all the SSS stuff if the color is 0.
    {
        //d.ndl = smoothstep(_SSSRange - _SSSSharpness, _SSSRange + _SSSSharpness, d.ndl);
        half attenuation = saturate(light.attenuation * (light.ndl * 0.5 + 0.5));
        half3 H = normalize(light.direction + normal * _SSDistortion);
        half VdotH = pow(saturate(dot(viewDir, -H)), _SSPower);
        half3 I = _SSColor * (VdotH + indirectDiffuse) * attenuation * i.thickness * _SSScale;
        half4 SSS = half4(light.color.rgb * I * i.albedo.rgb, 1);
        SSS = max(0, SSS); // Make sure it doesn't go NaN

        return SSS;
    }
    else
    {
        return 0;
    }
}

half4 GetEmission(FragmentData i, TextureUV t, DotProducts d, half lightAvg)
{
    #if defined(UNITY_PASS_FORWARDBASE) // Emission only in Base Pass, and vertex lights
        float4 emission = 0;
        if(_EmissionAudioLinkChannel == AUDIOLINK_OFF)
        {
            emission = lerp(i.emissionMap, i.emissionMap * i.diffuseColor.xyzz, _EmissionToDiffuse) * _EmissionColor;
        }
        else
        {
            if(AudioLinkIsAvailable())
            {
                if(_EmissionAudioLinkChannel != AUDIOLINK_PACKEDMAP)
                {
                    int2 aluv;
                    if (_EmissionAudioLinkChannel == AUDIOLINK_UV)
                    {
                        aluv = int2(t.emissionMapUV.x * _ALUVWidth, t.emissionMapUV.y);
                    } else
                    {
                        aluv = int2(0, (_EmissionAudioLinkChannel-1));
                    }
                    float alink = lerp(1, AudioLinkData(aluv).x , saturate(_EmissionAudioLinkChannel));
                    emission = lerp(i.emissionMap, i.emissionMap * i.diffuseColor.xyzz, _EmissionToDiffuse) * _EmissionColor * alink;
                }
                else
                {
                    float audioDataBass = AudioLinkData(ALPASS_AUDIOBASS).x;
                    float audioDataMids = AudioLinkData(ALPASS_AUDIOLOWMIDS).x;
                    float audioDataHighs = (AudioLinkData(ALPASS_AUDIOHIGHMIDS).x + AudioLinkData(ALPASS_AUDIOTREBLE).x) * 0.5;

                    float tLow = smoothstep((1-audioDataBass), (1-audioDataBass) + 0.01, i.emissionMap.r) * i.emissionMap.a;
                    float tMid = smoothstep((1-audioDataMids), (1-audioDataMids) + 0.01, i.emissionMap.g) * i.emissionMap.a;
                    float tHigh = smoothstep((1-audioDataHighs), (1-audioDataHighs) + 0.01, i.emissionMap.b) * i.emissionMap.a;

                    float4 emissionChannelRed = lerp(i.emissionMap.r, tLow, _ALGradientOnRed) * _EmissionColor * audioDataBass;
                    float4 emissionChannelGreen = lerp(i.emissionMap.g, tMid, _ALGradientOnGreen) * _EmissionColor0 * audioDataMids;
                    float4 emissionChannelBlue = lerp(i.emissionMap.b, tHigh, _ALGradientOnBlue) * _EmissionColor1 * audioDataHighs;
                    emission = (emissionChannelRed + emissionChannelGreen + emissionChannelBlue) * lerp(1, i.diffuseColor.rgbb, _EmissionToDiffuse);
                }
            }
        }

        float4 scaledEmission = emission * saturate(smoothstep(1-_ScaleWithLightSensitivity, 1+_ScaleWithLightSensitivity, 1-lightAvg));
        float4 em = lerp(scaledEmission, emission, _ScaleWithLight);

        em.rgb = rgb2hsv(em.rgb);
        em.x += fmod(_Hue, 360);
        em.y = saturate(em.y * _Saturation);
        em.z *= _Value;
        em.rgb = hsv2rgb(em.rgb);

        return em;
    #else
        return 0;
    #endif
}

void DoReflectionBlending(FragmentData i, inout half3 col, half3 indirectSpecular)
{
    if(_ReflectionBlendMode == 0) // Additive
        col += indirectSpecular * i.reflectivityMask.r;
    else if(_ReflectionBlendMode == 1) //Multiplicitive
        col = lerp(col, col * indirectSpecular, i.reflectivityMask.r);
    else if(_ReflectionBlendMode == 2) //Subtractive
        col -= indirectSpecular * i.reflectivityMask.r;
}

// void calcClearcoat(inout half4 col, FragmentData i, DotProducts d, half3 untouchedNormal, half3 indirectDiffuse, half3 lightCol, half3 viewDir, half3 lightDir, half4 ramp)
// {
//     UNITY_BRANCH
//     if(_ClearCoat != OPTION_OFF)
//     {
//         untouchedNormal = normalize(untouchedNormal);
//         half clearcoatSmoothness = _ClearcoatSmoothness * i.metallicGlossMap.g;
//         half clearcoatStrength = _ClearcoatStrength * i.metallicGlossMap.b;
//
//         half3 reflView = calcReflView(viewDir, untouchedNormal);
//         half3 reflLight = calcReflLight(lightDir, untouchedNormal);
//         half rdv = saturate( dot( reflLight, half4(-viewDir, 0) ));
//         half3 clearcoatIndirect = calcIndirectSpecular(i, d, half4(0, 0, 0, 1-clearcoatSmoothness), reflView, indirectDiffuse, viewDir, 1, ramp);
//         half3 clearcoatDirect = saturate(pow(rdv, clearcoatSmoothness * 256)) * i.attenuation * lightCol;
//
//         half3 clearcoat = (clearcoatIndirect + clearcoatDirect) * clearcoatStrength;
//         clearcoat = lerp(clearcoat * 0.5, clearcoat, saturate(pow(1-dot(viewDir, untouchedNormal), 0.8)) );
//         col += clearcoat.xyzz;
//     }
// }

// TODO:: these need to be flipped if mesh is not from blender.
half3 GetMeshForwardDirection()
{
    half3 forward = UNITY_MATRIX_M._m00_m10_m20;
    return forward;
}

// TODO:: these need to be flipped if mesh is not from blender.
half3 GetMeshRightDirection()
{
    half3 right = UNITY_MATRIX_M._m02_m12_m22;
    return right;
}

half3 GetMeshUpDirection()
{
    half3 up = UNITY_MATRIX_M._m01_m11_m21;
    return up;
}

Directions GetDirections(FragmentData i)
{
    Directions dirs = (Directions) 0;
    dirs.viewDir = calcViewDir(i.worldPos);
    dirs.stereoViewDir = calcStereoViewDir(i.worldPos);
    dirs.reflView = calcReflView(dirs.viewDir, i.normal);
    dirs.forward = GetMeshForwardDirection();
    dirs.right = GetMeshRightDirection();
    dirs.up = GetMeshUpDirection();
    return dirs;
}

DotProducts GetDots(Directions dirs, FragmentData i)
{
    DotProducts d = (DotProducts)0;
    d.vdn = abs(dot(dirs.viewDir, i.normal));
    d.svdn = abs(dot(dirs.stereoViewDir, i.normal));
    return d;
}

// Get the most intense light Dir from probes OR from a light source. Method developed by Xiexe / Merlin
half3 GetDominantLightDirection(FragmentData i)
{
    half3 lightDir = UnityWorldSpaceLightDir(i.worldPos);
    half3 probeLightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
    lightDir = (lightDir + probeLightDir); //Make light dir the average of the probe direction and the light source direction.
    #if !defined(POINT) && !defined(SPOT)// if the average length of the light probes is null, and we don't have a directional light in the scene, fall back to our fallback lightDir
    if(length(unity_SHAr.xyz*unity_SHAr.w + unity_SHAg.xyz*unity_SHAg.w + unity_SHAb.xyz*unity_SHAb.w) == 0 && length(lightDir) < 0.1)
    {
        lightDir = half4(1, 1, 1, 0);
    }
    #endif
    return normalize(lightDir);
}

half4 GetOutlineColor(FragmentData i, Light light, Light ambientLight)
{
    half3 outlineColor = half3(0,0,0);
    #if defined(Geometry)
        half3 ol = lerp(_OutlineColor, _OutlineColor * i.diffuseColor, _OutlineAlbedoTint);
        outlineColor = ol * saturate(i.attenuation * light.ndl) * light.color.rgb;
        outlineColor += ambientLight.color.rgb * ol;
        outlineColor = lerp(outlineColor, ol, _OutlineLighting);
    #endif
    return half4(outlineColor,1);
}

half3 GetAmbientColor()
{// We don't care about anything other than the color from probes for toon lighting.
    #if !defined(LIGHTMAP_ON)
        half3 indirectDiffuse = ShadeSH9(float4(0,0.5,0,1));//half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
        return indirectDiffuse;
    #else
        return 0;
    #endif
}

void GetExtraLightAttenuations(float3 worldPos, out half attenuations[4])
{
    half4 toLightX = unity_4LightPosX0 - worldPos.x;
    half4 toLightY = unity_4LightPosY0 - worldPos.y;
    half4 toLightZ = unity_4LightPosZ0 - worldPos.z;

    half4 lengthSq = 0;
    lengthSq += toLightX * toLightX;
    lengthSq += toLightY * toLightY;
    lengthSq += toLightZ * toLightZ;

    half4 atten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);
    half4 atten2 = saturate(1 - (lengthSq * unity_4LightAtten0 / 25));
    atten = min(atten, atten2 * atten2);

    attenuations[0] = atten.x;
    attenuations[1] = atten.y;
    attenuations[2] = atten.z;
    attenuations[3] = atten.w;
}

void PopulateLight(FragmentData i, Directions d, half3 color, half3 attenuation, half3 direction, inout Light light)
{
    light.color = color;
    light.attenuation = attenuation;
    light.direction = direction;
    
    light.reflectionVector = reflect(light.direction, i.normal);
    light.halfVector = normalize(light.direction + d.viewDir);
    
    light.ndl = dot(i.normal, light.direction);
    light.ldh = DotClamped(light.direction, light.halfVector);
    light.tdh = dot(i.tangent, light.halfVector);
    light.bdh = dot(i.bitangent, light.halfVector);
    light.ndh = DotClamped(i.normal, light.halfVector);
    light.vdh = DotClamped(d.viewDir, light.halfVector);
    
    light.rdv = saturate(dot(light.reflectionVector, float4(-d.viewDir, 0)));
    light.rdl = dot(d.right, light.direction);
    light.fdl = dot(d.forward, light.direction);
    
    light.isAbove = (d.up.y - light.direction.y) < 0 ? 1 : -1;
}

void PopulateExtraPassLights(FragmentData i, Directions d, inout Light lights[4])
{
    #if defined(UNITY_PASS_FORWARDBASE)
        #if defined(VERTEXLIGHT_ON)
            half attenuations[4];
            GetExtraLightAttenuations(i.worldPos, attenuations);
            
            for(int light = 0; light < 4; light++)
            {
                lights[light].type = LIGHT_TYPE_EXTRA;
                half3 toLight = float3(unity_4LightPosX0[light], unity_4LightPosY0[light], unity_4LightPosZ0[light]);
                half3 direction = toLight - i.worldPos;
                direction *= length(toLight) * attenuations[light];
                
                PopulateLight(i, d, unity_LightColor[light], attenuations[light], direction, lights[light]);
            }
        #endif
    #endif
}

half4 SampleShadowMap(half rdl, half2 uv)
{
    half2 flippedUv = half2(1-uv.x, uv.y);
    half2 correctUv = rdl > 0 ? uv : flippedUv;
    
    half4 shadow = tex2D(_ShadowControlTexture, correctUv);
    shadow.rgb += 0.125;
    return shadow;
}

half4 SampleShadowRamp(FragmentData i, TextureUV t, Light light)
{
    half remapRamp = (light.ndl * 0.5 + 0.5) * lerp(1, i.occlusion.r, _OcclusionMode);

    if(_UseShadowMapTexture > 0)
    {
        half4 shadowMap = SampleShadowMap(light.rdl, t.uv0);
        half normalizedFdotL = 1 * -0.5 * light.fdl + 0.5;
        normalizedFdotL %= 1;
        
        half shadowDir = smoothstep(shadowMap.x, 0, normalizedFdotL);
        remapRamp = lerp(remapRamp, shadowDir, shadowMap.a);
    }
    
    half4 ramp = tex2D(_Ramp, half2(remapRamp * light.attenuation, i.rampMask.r));
    return ramp;
}

void ApplyLight(FragmentData i, DotProducts d, TextureUV t, Directions dir, Light light, inout half3 diffuse, inout half3 specular, inout half3 subsurfaceScattering)
{
    half4 ramp = SampleShadowRamp(i, t, light);
    diffuse += ramp * light.color;
    specular += GetDirectSpecular(i, d, light, _AnisotropicSpecular) * light.ndl * light.attenuation;
    subsurfaceScattering += GetSubsurfaceScattering(i, light, dir.viewDir, i.normal, 0);
}

void ApplyMainLights(FragmentData i, DotProducts d, TextureUV t, Directions dir, Light mainLight, Light ambientLight, inout half3 diffuse, inout half3 specular, inout half3 subsurfaceScattering)
{
    half4 indirect = ambientLight.color.rgbb;

    half grayIndirect = dot(ambientLight.color.rgbb, float3(1,1,1));
    half attenFactor = lerp(mainLight.attenuation, 1, smoothstep(0, 0.2, grayIndirect));

    half4 ramp = SampleShadowRamp(i, t, mainLight);
    diffuse += ramp * mainLight.color * attenFactor + indirect;
    specular += GetDirectSpecular(i, d, mainLight, _AnisotropicSpecular) * mainLight.ndl * mainLight.attenuation;
    subsurfaceScattering += GetSubsurfaceScattering(i, mainLight, dir.viewDir, i.normal, ambientLight.color);
}

void ApplyExtraPassLights(FragmentData i, DotProducts d, TextureUV t, Directions dir, Light lights[4], inout half3 diffuse, inout half3 specular, inout half3 subsurfaceScattering)
{
    #if defined(UNITY_PASS_FORWARDBASE)
        #if defined(VERTEXLIGHT_ON)
            for(int light = 0; light < 4; light++)
            {
                ApplyLight(i, d, t, dir, lights[light], diffuse, specular, subsurfaceScattering);
            }
        #endif
    #endif
}

half3 GetRimLight(FragmentData i, DotProducts d, Light light, Light ambientLight, half3 envMap)
{
    #if defined(UNITY_PASS_FORWARDBASE)
        half rimIntensity = saturate((1-d.svdn)) * pow(light.ndl, _RimThreshold);
        rimIntensity = smoothstep(_RimRange - _RimSharpness, _RimRange + _RimSharpness, rimIntensity);
        half3 rim = rimIntensity * _RimIntensity * (light.color + ambientLight.color);
        rim *= lerp(1, i.attenuation + ambientLight.color, _RimAttenEffect);

        half3 rimLight = rim * _RimColor * lerp(1, i.diffuseColor.rgbb, _RimAlbedoTint) * lerp(1, envMap.rgbb, _RimCubemapTint);
        return rimLight;
    #endif

    return 0;
}

half3 GetRimShadow(FragmentData i, DotProducts d, Light light, Light ambientLight)
{
    #if defined(UNITY_PASS_FORWARDBASE)
        half rimIntensity = saturate((1-d.svdn)) * pow(1-light.ndl, _ShadowRimThreshold * 2);
        rimIntensity = smoothstep(_ShadowRimRange - _ShadowRimSharpness, _ShadowRimRange + _ShadowRimSharpness, rimIntensity);
        half3 shadowRim = lerp(1, (_ShadowRim * lerp(1, i.diffuseColor.rgbb, _ShadowRimAlbedoTint)) + (ambientLight.color * 0.1), rimIntensity);
        return shadowRim;
    #endif

    return 1;
}

void ApplyHalftones(FragmentData i, inout half3 specular, inout half3 rimLight, inout half3 shadowRim, inout half3 ramp)
{
    if(_HalftoneType == HALFTONE_SHADOWS || _HalftoneType == HALFTONE_SHADOWS_AND_HIGHLIGHTS)
    {
        half lineHalftone = lerp(1, LineHalftone(i, 1), 1-saturate(dot(shadowRim * ramp, grayscaleVec)));
        ramp *= lerp(1, lineHalftone, _HalftoneLineIntensity);
    }
    
    if(_HalftoneType == HALFTONE_HIGHLIGHTS || _HalftoneType == HALFTONE_SHADOWS_AND_HIGHLIGHTS)
    {
        half stipplingSpecular = DotHalftone(i, saturate(dot(specular, grayscaleVec))) * saturate(dot(shadowRim * ramp, grayscaleVec));
        half stipplingRim = DotHalftone(i, saturate(dot(rimLight, grayscaleVec))) * saturate(dot(shadowRim * ramp, grayscaleVec));

        rimLight *= stipplingRim;
        specular *= stipplingSpecular;
    }
}
