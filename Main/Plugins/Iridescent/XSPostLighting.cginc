float4 PostLightingHook(float4 finalColor, HookData data)
{
    DotProducts d = data.d;
    
    // Iridescent
    float4 irMap = UNITY_SAMPLE_TEX2D_SAMPLER(_Iridescent, _MainTex, pow(d.vdn, _IridescentSamplingPow));
    irMap *= pow(saturate(d.ndl + 0.5), 0.5);
    irMap *= _IridescentColor;
    finalColor += irMap * pow(d.vdn, _IridescentRimPower);
    return finalColor;
}
