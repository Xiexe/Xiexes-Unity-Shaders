void AdjustAlbedo(inout FragmentData i, TextureUV t)
{
    #if defined(_FUR_SHELL)
        float lengthMask = tex2D(_FurLengthMask, t.uv0 * _FurLengthMask_ST.xy + _FurLengthMask_ST.zw).x;
        float layerScalar = i.layer / _LayerCount;
        float2 furUV = t.uv0 * _FurTexture_ST.xy + _FurTexture_ST.zw;
        furUV.x += _CombX * i.layer * 0.001;
        furUV.y += _CombY * i.layer * 0.001;

        float4 furAlbedo = tex2D(_FurTexture, furUV);
        float colorBlend = smoothstep(_ColorFalloffMin, _ColorFalloffMax, layerScalar);
        i.albedo = lerp(i.albedo, furAlbedo, saturate(i.layer)) * lerp(1, lerp(_BottomColor, _TopColor, colorBlend), lengthMask);
    #elif defined(_FUR_FIN)
        float2 furUV = t.uv0 * _FurTexture_ST.xy + _FurTexture_ST.zw;
        float4 furAlbedo = tex2D(_FurTexture, furUV);
        float colorBlend = smoothstep(_ColorFalloffMin, _ColorFalloffMax, t.uv0.y);
        i.albedo = lerp(i.albedo, furAlbedo, saturate(i.layer)) * lerp(1, lerp(_BottomColor, _TopColor, colorBlend), 1);
    #endif
}

void DoFurAlpha(FragmentData i, TextureUV t, inout float alpha)
{
    #if defined(_FUR_SHELL)
        float lengthMask = tex2D(_FurLengthMask, t.uv0 * _FurLengthMask_ST.xy + _FurLengthMask_ST.zw).x;

        float layer = i.layer;
        float layerScalar = (layer / _LayerCount);

        float2 furUV = t.uv0 * _StrandAmount;
        furUV.x += _CombX * layer * 0.01;
        furUV.y += _CombY * layer * 0.01;

        float4 noise = tex2D(_NoiseTexture, furUV);

        if(layer != 0)
        {
            float clipMap = (layerScalar * (1-_FurWidth)) + (1-lengthMask);
            alpha = smoothstep(0, 0.05, saturate(noise.r - clipMap));
        }
        else
        {
            float modifiedAlpha = lerp(AdjustAlphaUsingTextureArray(i, i.albedo.a), i.albedo.a, _UseClipsForDissolve);
            half dither = calcDither(i.screenUV.xy);
            alpha = modifiedAlpha - (dither * (1-i.albedo.a) * 0.15);
            #if defined(UNITY_PASS_SHADOWCASTER)
                clip(modifiedAlpha - dither);
            #endif
        }
    #elif defined(_FUR_FIN)
        float modifiedAlpha = lerp(AdjustAlphaUsingTextureArray(i, i.albedo.a), i.albedo.a, _UseClipsForDissolve);
        half dither = calcDither(i.screenUV.xy);
        alpha = modifiedAlpha - (dither * (1-i.albedo.a) * 0.15);
        #if defined(UNITY_PASS_SHADOWCASTER)
            clip(modifiedAlpha - dither);
        #endif
    #endif
}

void AdjustFurSpecular(FragmentData i, inout float3 totalSpecularLight)
{
    float layerScalar = i.layer / _LayerCount;
    totalSpecularLight *= layerScalar;
}