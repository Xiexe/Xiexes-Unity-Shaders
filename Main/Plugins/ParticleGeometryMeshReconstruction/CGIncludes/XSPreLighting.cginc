HookData PreLightingHook(HookData data)
{
    if(!data.isFrontface)
    {
        float4 metalGloss = data.i.metallicGlossMap;
        metalGloss.x = 1;
        metalGloss.a = 0.9;
        data.i.metallicGlossMap = metalGloss;
        data.i.albedo = 1;
    }
    return data;
}
