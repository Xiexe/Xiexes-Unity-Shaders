﻿sampler2D _NoiseTexture; float4 _NoiseTexture_ST;
sampler2D _FurLengthMask; float4 _FurLengthMask_ST;
sampler2D _FurTexture; float4 _FurTexture_ST;

float4 _TopColor;
float4 _BottomColor;
float _FurLength;
float _FurWidth;
float _Gravity;
float _CombX;
float _CombY;
float _FurOcclusion;
float _OcclusionFalloffMin;
float _OcclusionFalloffMax;
float _ColorFalloffMin;
float _ColorFalloffMax;
int _StrandAmount;
int _LayerCount;