//Helper Functions for Reflections
float pow5(float a)
{
    return a * a * a * a * a;
}

float3 F_Schlick(float u, float3 f0)
{
    return f0 + (1.0 - f0) * pow(1.0 - u, 5.0);
}

float3 F_Schlick(const float3 f0, float f90, float VoH)
{
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
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

half3 F_Schlick(half3 SpecularColor, half VoH)
{
    return SpecularColor + (1.0 - SpecularColor) * exp2((-5.55473 * VoH) - (6.98316 * VoH));
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

half3 rgb2hsv(half3 c)
{
    half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    half4 p = lerp(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
    half4 q = lerp(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return half3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

half3 hsv2rgb(half3 c)
{
    half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    half3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
//

half3 getVertexLightsDir(XSLighting i, half4 vertexLightAtten)
{
    half3 toLightX = half3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
    half3 toLightY = half3(unity_4LightPosX0.y, unity_4LightPosY0.y, unity_4LightPosZ0.y);
    half3 toLightZ = half3(unity_4LightPosX0.z, unity_4LightPosY0.z, unity_4LightPosZ0.z);
    half3 toLightW = half3(unity_4LightPosX0.w, unity_4LightPosY0.w, unity_4LightPosZ0.w);

    half3 dirX = toLightX - i.worldPos;
    half3 dirY = toLightY - i.worldPos;
    half3 dirZ = toLightZ - i.worldPos;
    half3 dirW = toLightW - i.worldPos;

    dirX *= length(toLightX) * vertexLightAtten.x * unity_LightColor[0];
    dirY *= length(toLightY) * vertexLightAtten.y * unity_LightColor[1];
    dirZ *= length(toLightZ) * vertexLightAtten.z * unity_LightColor[2];
    dirW *= length(toLightW) * vertexLightAtten.w * unity_LightColor[3];

    half3 dir = (dirX + dirY + dirZ + dirW) / 4;
    return dir;
}

// Get the most intense light Dir from probes OR from a light source. Method developed by Xiexe / Merlin
half3 calcLightDir(XSLighting i, half4 vertexLightAtten)
{
    half3 lightDir = UnityWorldSpaceLightDir(i.worldPos);

    half3 probeLightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
    lightDir = (lightDir + probeLightDir); //Make light dir the average of the probe direction and the light source direction.

    #if defined(VERTEXLIGHT_ON)
        half3 vertexDir = getVertexLightsDir(i, vertexLightAtten);
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

half3 get4VertexLightsColFalloff(half3 worldPos, half3 normal, inout half4 vertexLightAtten)
{
    half3 lightColor = 0;
    half4 toLightX = unity_4LightPosX0 - worldPos.x;
    half4 toLightY = unity_4LightPosY0 - worldPos.y;
    half4 toLightZ = unity_4LightPosZ0 - worldPos.z;

    half4 lengthSq = 0;
    lengthSq += toLightX * toLightX;
    lengthSq += toLightY * toLightY;
    lengthSq += toLightZ * toLightZ;

    float4 atten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);
    float4 atten2 = saturate(1 - (lengthSq * unity_4LightAtten0 / 25));
    atten = min(atten, atten2 * atten2);

    // half4 atten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);
    // atten = saturate(atten*atten); // Cleaner, nicer looking falloff. Also prevents the "Snapping in" effect that Unity's normal integration of vertex lights has.
    half4 colorFalloff = smoothstep(-0.7, 1.3, atten);
    vertexLightAtten = atten;

    half gs0 = dot(unity_LightColor[0], grayscaleVec);
    half gs1 = dot(unity_LightColor[1], grayscaleVec);
    half gs2 = dot(unity_LightColor[2], grayscaleVec);
    half gs3 = dot(unity_LightColor[3], grayscaleVec);
    //This is lerping between a white color and the actual color of the light based on the falloff, that way with our lighting model
    //we don't end up with *very* red/green/blue lights. This is a stylistic choice and can be removed for other lighting models.
    //without it, it would just be "lightColor.rgb = unity_Lightcolor[i] * atten.x/y/z/w;"
    lightColor.rgb += unity_LightColor[0]* atten.x;
    lightColor.rgb += unity_LightColor[1]* atten.y;
    lightColor.rgb += unity_LightColor[2]* atten.z;
    lightColor.rgb += unity_LightColor[3]* atten.w;

    return lightColor;
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

half3 calcDirectSpecular(XSLighting i, DotProducts d, half4 lightCol, half3 halfVector, half3 indirectDiffuse, half anisotropy)
{
    half specularIntensity = _SpecularIntensity * i.specularMap.r;
    half3 specular = half3(0,0,0);
    half smoothness = max(0.01, (_SpecularArea * i.specularMap.b));
    smoothness *= 1.7 - 0.7 * smoothness;

    float rough = max(smoothness * smoothness, 0.0045);
    float Dn = D_GGX(d.ndh, rough);
    float3 F = F_Schlick(d.ldh, 1);
    float V = V_SmithGGXCorrelated(d.vdn, d.ndl, rough);
    float3 directSpecularNonAniso = max(0, (Dn * V) * F);

    anisotropy *= saturate(5.0 * smoothness);
    float at = max(rough * (1.0 + anisotropy), 0.001);
    float ab = max(rough * (1.0 - anisotropy), 0.001);
    float D = D_GGX_Anisotropic(d.ndh, halfVector, i.tangent, i.bitangent, at, ab);
    float3 directSpecularAniso = max(0, (D * V) * F);

    specular = lerp(directSpecularNonAniso, directSpecularAniso, saturate(abs(anisotropy * 100)));
    specular = lerp(specular, smoothstep(0.5, 0.51, specular), _SpecularSharpness) * i.attenuation * lightCol * specularIntensity;
    specular *= lerp(1, i.diffuseColor, _SpecularAlbedoTint * i.specularMap.g);
    return specular;
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

half4 calcRamp(XSLighting i, DotProducts d)
{
    half remapRamp;
    remapRamp = (d.ndl * lerp(1, i.occlusion.r, _OcclusionMode) * 0.5 + 0.5);

    #if defined(UNITY_PASS_FORWARDBASE)
       remapRamp *= i.attenuation;
    #endif

    half4 ramp = tex2D( _Ramp, half2(remapRamp, i.rampMask.r) );

    return ramp;
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
        half3 clearcoatIndirect = calcIndirectSpecular(i, d, half4(0, 0, 0, 1-clearcoatSmoothness), reflView, indirectDiffuse, viewDir, 1, ramp);
        half3 clearcoatDirect = saturate(pow(rdv, clearcoatSmoothness * 256)) * i.attenuation * lightCol;

        half3 clearcoat = (clearcoatIndirect + clearcoatDirect) * clearcoatStrength;
        clearcoat = lerp(clearcoat * 0.5, clearcoat, saturate(pow(1-dot(viewDir, untouchedNormal), 0.8)) );
        col += clearcoat.xyzz;
    }
}
