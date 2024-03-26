HookData PreLightingHook(HookData data)
{
    if(!data.isFrontface)
    {
        float4 metalGloss = data.frag.metallicGlossMap;
        metalGloss.x = 1;
        metalGloss.a = 0.9;
        data.frag.metallicGlossMap = metalGloss;
        data.frag.albedo = 1;
    }
    return data;
}
