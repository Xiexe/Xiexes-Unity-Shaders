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

half3 calcReflLight(half3 lightDir, half3 normal)
{
    return reflect(lightDir, normal);
}
//

//Returns the average direction of all lights and writes to a struct contraining individual directions
float3 getVertexLightsDir(inout VertexLightInformation vLights, float3 worldPos, float4 vertexLightAtten)
{
    float3 dir = float3(0,0,0);
    float3 toLightX = float3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
    float3 toLightY = float3(unity_4LightPosX0.y, unity_4LightPosY0.y, unity_4LightPosZ0.y);
    float3 toLightZ = float3(unity_4LightPosX0.z, unity_4LightPosY0.z, unity_4LightPosZ0.z);
    float3 toLightW = float3(unity_4LightPosX0.w, unity_4LightPosY0.w, unity_4LightPosZ0.w);

    float3 dirX = toLightX - worldPos;
    float3 dirY = toLightY - worldPos;
    float3 dirZ = toLightZ - worldPos;
    float3 dirW = toLightW - worldPos;

    dirX *= length(toLightX) * vertexLightAtten.x;
    dirY *= length(toLightY) * vertexLightAtten.y;
    dirZ *= length(toLightZ) * vertexLightAtten.z;
    dirW *= length(toLightW) * vertexLightAtten.w;

    vLights.Direction[0] = dirX;
    vLights.Direction[1] = dirY;
    vLights.Direction[2] = dirZ;
    vLights.Direction[3] = dirW;

    dir = (dirX + dirY + dirZ + dirW) / 4;
    return dir;
}

// Get the most intense light Dir from probes OR from a light source. Method developed by Xiexe / Merlin
half3 calcLightDir(XSLighting i)
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

void calcLightCol(bool lightEnv, inout half3 indirectDiffuse, inout half4 lightColor)
{
    //If we're in an environment with a realtime light, then we should use the light color, and indirect color raw.
    //...
    if(lightEnv)
    {
        lightColor = _LightColor0;
        indirectDiffuse = indirectDiffuse;
    }
    else
    {
        lightColor = indirectDiffuse.xyzz * 0.6;    // ...Otherwise
        indirectDiffuse = indirectDiffuse * 0.4;    // Keep overall light to 100% - these should never go over 100%
                                                    // ex. If we have indirect 100% as the light color and Indirect 50% as the indirect color,
                                                    // we end up with 150% of the light from the scene.
    }
}

float3 get4VertexLightsColFalloff(inout VertexLightInformation vLight, float3 worldPos, float3 normal, inout float4 vertexLightAtten)
{
    float3 lightColor = 0;
    #if defined(VERTEXLIGHT_ON)
    float4 toLightX = unity_4LightPosX0 - worldPos.x;
    float4 toLightY = unity_4LightPosY0 - worldPos.y;
    float4 toLightZ = unity_4LightPosZ0 - worldPos.z;

    float4 lengthSq = 0;
    lengthSq += toLightX * toLightX;
    lengthSq += toLightY * toLightY;
    lengthSq += toLightZ * toLightZ;

    float4 atten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);
    float4 atten2 = saturate(1 - (lengthSq * unity_4LightAtten0 / 25));
    atten = min(atten, atten2 * atten2);
    // Cleaner, nicer looking falloff. Also prevents the "Snapping in" effect that Unity's normal integration of vertex lights has.
    vertexLightAtten = atten;

    lightColor.rgb += unity_LightColor[0] * atten.x;
    lightColor.rgb += unity_LightColor[1] * atten.y;
    lightColor.rgb += unity_LightColor[2] * atten.z;
    lightColor.rgb += unity_LightColor[3] * atten.w;

    vLight.ColorFalloff[0] = unity_LightColor[0] * atten.x;
    vLight.ColorFalloff[1] = unity_LightColor[1] * atten.y;
    vLight.ColorFalloff[2] = unity_LightColor[2] * atten.z;
    vLight.ColorFalloff[3] = unity_LightColor[3] * atten.w;

    vLight.Attenuation[0] = atten.x;
    vLight.Attenuation[1] = atten.y;
    vLight.Attenuation[2] = atten.z;
    vLight.Attenuation[3] = atten.w;
    #endif
    return lightColor;
}

half4 calcRamp(XSLighting i, DotProducts d)
{
    half remapRamp;
    remapRamp = (d.ndl * 0.5 + 0.5) * lerp(1, i.occlusion.r, _OcclusionMode) ;
    #if defined(UNITY_PASS_FORWARDBASE)
    remapRamp *= i.attenuation;
    #endif
    half4 ramp = tex2D(_Ramp, half2(remapRamp, i.rampMask.r));
    return ramp;
}

half4 calcRampShadowOverride(XSLighting i, float ndl)
{
    half remapRamp;
    remapRamp = (ndl * 0.5 + 0.5) * lerp(1, i.occlusion.r, _OcclusionMode);
    half4 ramp = tex2D(_Ramp, half2(remapRamp, i.rampMask.r));
    return ramp;
}

float3 getVertexLightsDiffuse(XSLighting i, VertexLightInformation vLight)
{
    float3 vertexLightsDiffuse = 0;
    #if defined(VERTEXLIGHT_ON)
        for(int light = 0; light < 4; light++) // I know, I know, not using i. Blame my structs.
        {
            float vLightNdl = dot(vLight.Direction[light], i.normal);
            vertexLightsDiffuse += calcRampShadowOverride(i, vLightNdl) * vLight.ColorFalloff[light];
        }
    #endif
    return vertexLightsDiffuse;
}

half4 calcMetallicSmoothness(XSLighting i)
{
    half roughness = 1-(_Glossiness * i.metallicGlossMap.a);
    roughness *= 1.7 - 0.7 * roughness;
    half metallic = lerp(0, i.metallicGlossMap.r * _Metallic, i.reflectivityMask.r);
    return half4(metallic, 0, 0, roughness);
}

half4 calcRimLight(XSLighting i, DotProducts d, half4 lightCol, half3 indirectDiffuse, half3 envMap)
{
    half rimIntensity = saturate((1-d.svdn)) * pow(d.ndl, _RimThreshold);
    rimIntensity = smoothstep(_RimRange - _RimSharpness, _RimRange + _RimSharpness, rimIntensity);
    half4 rim = rimIntensity * _RimIntensity * (lightCol + indirectDiffuse.xyzz);
    rim *= lerp(1, i.attenuation + indirectDiffuse.xyzz, _RimAttenEffect);
    return rim * _RimColor * lerp(1, i.diffuseColor.rgbb, _RimAlbedoTint) * lerp(1, envMap.rgbb, _RimCubemapTint);
}

half4 calcShadowRim(XSLighting i, DotProducts d, half3 indirectDiffuse)
{
    half rimIntensity = saturate((1-d.svdn)) * pow(1-d.ndl, _ShadowRimThreshold * 2);
    rimIntensity = smoothstep(_ShadowRimRange - _ShadowRimSharpness, _ShadowRimRange + _ShadowRimSharpness, rimIntensity);
    half4 shadowRim = lerp(1, (_ShadowRim * lerp(1, i.diffuseColor.rgbb, _ShadowRimAlbedoTint)) + (indirectDiffuse.xyzz * 0.1), rimIntensity);

    return shadowRim ;
}

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

half3 calcDirectSpecular(XSLighting i, float ndl, float ndh, float vdn, float ldh, half4 lightCol, half3 halfVector, half anisotropy)
{
    half specularIntensity = _SpecularIntensity * i.specularMap.r;
    half3 specular = half3(0,0,0);
    half smoothness = max(0.01, (_SpecularArea * i.specularMap.b));
    smoothness *= 1.7 - 0.7 * smoothness;

    float rough = max(smoothness * smoothness, 0.0045);
    float Dn = D_GGX(ndh, rough);
    float3 F = 1-F_Schlick(ldh, 0);
    float V = V_SmithGGXCorrelated(vdn, ndl, rough);
    float3 directSpecularNonAniso = max(0, (Dn * V) * F);

    anisotropy *= saturate(5.0 * smoothness);
    float at = max(rough * (1.0 + anisotropy), 0.001);
    float ab = max(rough * (1.0 - anisotropy), 0.001);
    float D = D_GGX_Anisotropic(ndh, halfVector, i.tangent, i.bitangent, at, ab);
    float3 directSpecularAniso = max(0, (D * V) * F);

    specular = lerp(directSpecularNonAniso, directSpecularAniso, saturate(abs(anisotropy * 100)));
    specular = lerp(specular, smoothstep(0.5, 0.51, specular), _SpecularSharpness) * 3 * lightCol * specularIntensity; // Multiply by 3 to bring up to brightness of standard
    specular *= lerp(1, i.diffuseColor, _SpecularAlbedoTint * i.specularMap.g);
    return specular;
}

float3 getVertexLightSpecular(XSLighting i, DotProducts d, VertexLightInformation vLight, float3 normal, float3 viewDir, float anisotropy)
{
    float3 vertexLightSpec = 0;
    #if defined(VERTEXLIGHT_ON)
        for(int light = 0; light < 4; light++)
        {
            // All of these need to be recalculated for each individual light to treat them how we want to treat them.
            float3 vHalfVector = normalize(vLight.Direction[light] + viewDir);
            float vNDL = saturate(dot(vLight.Direction[light], normal));
            float vLDH = saturate(dot(vLight.Direction[light], vHalfVector));
            float vNDH = saturate(dot(normal, vHalfVector));
            vertexLightSpec += calcDirectSpecular(i, vNDL, vNDH, d.vdn, vLDH, vLight.ColorFalloff[light].rgbb, vHalfVector, anisotropy) * vNDL;
        }
    #endif
    return vertexLightSpec;
}

half3 calcIndirectSpecular(XSLighting i, DotProducts d, half4 metallicSmoothness, half3 reflDir, half3 indirectLight, half3 viewDir, float3 fresnel, half4 ramp)
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
            spec = indirectSpecular * fresnel;
        #endif
    }
    else if(_ReflectionMode == 1) //Baked Cubemap
    {
        half3 indirectSpecular = texCUBElod(_BakedCubemap, half4(reflDir, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS));;
        spec = indirectSpecular * fresnel;

        if(_ReflectionBlendMode != 1)
        {
            spec *= (indirectLight + (_LightColor0 * i.attenuation) * 0.5);
        }
    }
    else if (_ReflectionMode == 2) //Matcap
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

half4 calcOutlineColor(XSLighting i, DotProducts d, half3 indirectDiffuse, half4 lightCol)
{
    half3 outlineColor = half3(0,0,0);
    #if defined(Geometry)
        half3 ol = lerp(_OutlineColor, _OutlineColor * i.diffuseColor, _OutlineAlbedoTint);
        outlineColor = ol * saturate(i.attenuation * d.ndl) * lightCol.rgb;
        outlineColor += indirectDiffuse * ol;
        outlineColor = lerp(outlineColor, ol, _OutlineLighting);
    #endif
    return half4(outlineColor,1);
}

half3 calcIndirectDiffuse(XSLighting i)
{// We don't care about anything other than the color from probes for toon lighting.
    half3 indirectDiffuse = ShadeSH9(float4(0,0.5,0,1));//half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    return indirectDiffuse;
}

half4 calcDiffuse(XSLighting i, DotProducts d, half3 indirectDiffuse, half4 lightCol, half4 ramp)
{
    half4 diffuse;
    half4 indirect = indirectDiffuse.xyzz;

    half grayIndirect = dot(indirectDiffuse, float3(1,1,1));
    half attenFactor = lerp(i.attenuation, 1, smoothstep(0, 0.2, grayIndirect));

    diffuse = ramp * attenFactor * lightCol + indirect;
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
        //d.ndl = smoothstep(_SSSRange - _SSSSharpness, _SSSRange + _SSSSharpness, d.ndl);
        half attenuation = saturate(i.attenuation * (d.ndl * 0.5 + 0.5));
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
        float4 emission = lerp(i.emissionMap, i.emissionMap * i.diffuseColor.xyzz, _EmissionToDiffuse);
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
        half3 clearcoatIndirect = calcIndirectSpecular(i, d, half4(0, 0, 0, 1-clearcoatSmoothness), reflView, indirectDiffuse, viewDir, 1, ramp);
        half3 clearcoatDirect = saturate(pow(rdv, clearcoatSmoothness * 256)) * i.attenuation * lightCol;

        half3 clearcoat = (clearcoatIndirect + clearcoatDirect) * clearcoatStrength;
        clearcoat = lerp(clearcoat * 0.5, clearcoat, saturate(pow(1-dot(viewDir, untouchedNormal), 0.8)) );
        col += clearcoat.xyzz;
    }
}
