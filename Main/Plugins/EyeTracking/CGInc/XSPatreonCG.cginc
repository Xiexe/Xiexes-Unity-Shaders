float _LeftRightPan;
float _UpDownPan;
float _Twitchyness;
float _AttentionSpan;
float _FollowPower;
float _FollowLimit;
float _LookSpeed;
float _IrisSize;
float _EyeOffsetLimit;

float rand(float n){return frac(sin(n) * 43758.5453123);}
float randStepped(float n) { return step(frac(sin(n) * 43758.5453123), _AttentionSpan); }

float pnoise(float p)
{
	float f = frac(p);
	float i = floor(p);
	float left = rand(i);
	float right = rand(i + 1);
	f = f * f * (3 - 2 * f);
	float n = lerp(left, right, f);

	return -1 + 2 * n;
}

float pnoise2(float p)
{
	float f = frac(p);
	float i = floor(p);
	float left = randStepped(i);
	float right = randStepped(i + 1);
	f = f * f * (3 - 2 * f);
	float n = lerp(left, right, f);

	return -1 + 2 * n;
}

float smoothRounded(float p)
{
	float f = frac(p);
	float i = floor(p);
	float left = pnoise2(i);
	float right = pnoise2(i + 1.);
	f = f * f * (3. - 2.*f);
	float n = lerp(left, right, f);
	n = n * 0.5 + 0.5;
	_LookSpeed = 1-_LookSpeed;
	_LookSpeed *= 0.2;

	return smoothstep(.37 - _LookSpeed * 0.5, .37 + _LookSpeed * 0.5, n);
}

float3 getTrackedEyes(float3 normal, float3 worldPos, float3 objPos, float noise)
{
    float3 cameraPos = _WorldSpaceCameraPos;
    #if UNITY_SINGLE_PASS_STEREO
        cameraPos = half3((unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) * .5); 
    #endif

    float3 objCamera = normalize(mul(unity_WorldToObject, float4(cameraPos, 1)));

    float3 viewDir = normalize(objCamera - objPos); //OBJECT SPACE VIEWDIR

    float followRadius = dot(objCamera, float3(0,0,1));
    followRadius = saturate((followRadius-(_FollowLimit * 0.2))*100);
    
    float dist = 1-distance(objCamera, objPos);
    
    viewDir.y += 0.1;
    viewDir.x *= 0.7;

    float3 trackedEyes = lerp(float3(0,0,1), float3(viewDir.xy, 1) * dist, followRadius * _FollowPower * noise);
    return trackedEyes;
}

float2 eyeOffsets(float2 uv, float3 objPos, float3 worldPos, float3 normal)
{
    //Separate left/Right eye
    float eyeMask = step(objPos.x, 0);
    
    uv.x = lerp(1-uv.x, uv.x, eyeMask);
    //Manual eye movements
    uv.x += _LeftRightPan;
    uv.y += _UpDownPan;

    //Auto Eye Movments
    float timescale = _Time.y * _Twitchyness;
    float perlinNoiseOffsets = pnoise(round(timescale));
    float2 modifyUV = float2(perlinNoiseOffsets * 0.01 , perlinNoiseOffsets * 0.5);
    float2 eyeOffsets = float2(rand(modifyUV.x), rand(modifyUV.y));
    eyeOffsets = 2*eyeOffsets-1;
    eyeOffsets.x *= 0.01;
    eyeOffsets.x = clamp(eyeOffsets.x, -0.01, 0.01);

    uv.x += eyeOffsets.x;
    uv.y += eyeOffsets.y * 0.01;

    //Follow/Tracking
    float perlinNoiseTracking = smoothRounded(_Time.y * 0.2);
    float3 eyeTrack = getTrackedEyes(normal, worldPos, objPos, perlinNoiseTracking);

	uv.x += clamp(eyeTrack.x, -_EyeOffsetLimit, _EyeOffsetLimit);
    uv.y -= clamp(eyeTrack.y, -_EyeOffsetLimit, _EyeOffsetLimit);

    //Scale Iris
    uv -= 0.5;
    uv /= _IrisSize;
    uv += 0.5;

    //Saturate UV so the texture doesn't repeat.
    uv = saturate(uv); 
    return uv;
}