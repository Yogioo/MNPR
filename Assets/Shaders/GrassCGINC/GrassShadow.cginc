// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef GRASS_SHADOW_INCLUDED
	#define GRASS_SHADOW_INCLUDED

	#pragma vertex vert
	#pragma fragment frag
	#define UNITY_PASS_SHADOWCASTER
	#include "UnityCG.cginc"
	#include "Lighting.cginc"
	#pragma multi_compile_shadowcaster
	#pragma multi_compile_fog

	struct appdata{
		float4 vertex:POSITION;
		float2 uv:TEXCOORD0;	
	};

	struct v2f{
		//float2 uv:TEXCOORD0;
		float4 pos:SV_POSITION;
		float2 uv:TEXCOORD0;
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;
	float _Cutoff;
	float3 _ReceiveShadowColor;
	float2 _WindDir;
	float _WindStrength,_WindDensity;
	float _PositionArrayCount;
	float3 _ObstaclePositions[100];
	float _InteractiveRange,_InteractiveStrength;
	//-----------------------------Noise Map--------------------------------------------------------
	float2 Unity_GradientNoise_Dir_float(float2 p)
	{
		// Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
		p = p % 289;
		float x = (34 * p.x + 1) * p.x % 289 + p.y;
		x = (34 * x + 1) * x % 289;
		x = frac(x / 41) * 2 - 1;
		return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
	}

	void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
	{ 
		float2 p = UV * Scale;
		float2 ip = floor(p);
		float2 fp = frac(p);
		float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
		float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
		float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
		float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
		fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
		Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
	}


	v2f vert (appdata v)
	{
		// -----------------Grass Vertex Movement Start-----------------
		float4 OriginPosWorld = mul(unity_ObjectToWorld, v.vertex);
		float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
		//v.vertex.y += 1;
		float2 noiseUV = posWorld.xz + _Time.y * _WindDir.xy;
		float noiseOffset;
		Unity_GradientNoise_float(noiseUV,_WindDensity,noiseOffset); // 风长(一次风能吹动多少草)
		noiseOffset-= 0.5f; // -.5~.5
		noiseOffset *= _WindStrength; // 风强度
		float4 newWorldPos = posWorld + float4(noiseOffset,0,0,0);
		posWorld = lerp(posWorld,newWorldPos,v.uv.y);

		// Interactive Grass Movement
		for (int n = 0; n<_PositionArrayCount;n++){
			float2 dir =  OriginPosWorld.xz - _ObstaclePositions[n].xz;
			float dirLength = length(dir);
			dirLength =_InteractiveRange-clamp(dirLength,0,_InteractiveRange); // Clamp踩草长度
			float2 value=  dirLength * dir * v.uv.y;
			value = clamp(value,-_InteractiveStrength,_InteractiveStrength);
			posWorld.xz += value;
			posWorld.y -=abs(value);
		}

		v.vertex =  mul(unity_WorldToObject,posWorld);


		// -----------------Grass Vertex Movement Over-----------------


		v2f o;		
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.uv,_MainTex);
		TRANSFER_SHADOW_CASTER (o); // make light work
		return o;
	}

	float4 frag(v2f i) : COLOR
	{
		clip(tex2D(_MainTex,i.uv).a - _Cutoff);
		SHADOW_CASTER_FRAGMENT(i)
	}

#endif // UNITY_STANDARD_SHADOW_INCLUDED
