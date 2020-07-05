Shader "Xiexe/Toon2.0/XSToonStenciler"
{
	Properties
	{
		[Header(Stencil)]
		_Offset("Offset", float) = 0
		_Stencil ("Stencil ID [0;255]", Float) = 0
		// _ReadMask ("ReadMask [0;255]", Int) = 255
		// _WriteMask ("WriteMask [0;255]", Int) = 255
		[Enum(Off, 0, Front,1, Back, 2)] _Culling ("Culling Mode", Int) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 8
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Int) = 2
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Stencil Fail", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("Stencil ZFail", Int) = 0
		[Enum(Off,0,On,1)] _ZWrite("ZWrite", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
		[Enum(None,0,Alpha,1,Red,8,Green,4,Blue,2,RGB,14,RGBA,15)] _colormask("Color Mask", Int) = 15 
	}
	SubShader
	{
		Tags { "RenderType"="" "Queue" = "Geometry-1" }
		LOD 100

		Cull [_Culling]
		Blend [_srcblend] [_dstblend]
		ColorMask [_colormask]
		ZTest [_ZTest]
		ZWrite [_ZWrite]

		Stencil
		{
			Ref [_Stencil]
			ReadMask 255
			WriteMask 255
			Comp [_StencilComp]
			Pass [_StencilOp]
			Fail [_StencilFail]
			ZFail [_StencilZFail]
		}

		Pass
		{
		}
	}
}
