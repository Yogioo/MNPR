#ifndef ITEM_PROPERTY_DEF
    #define ITEM_PROPERTY_DEF

    #include "AutoLight.cginc"

    struct FragmentCommonData
    {
        half3 diffColor, specColor;
        // Note: smoothness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
        // Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
        half oneMinusReflectivity, smoothness;
        float3 normalWorld;
        float3 eyeVec;
        half alpha;
        float3 posWorld;

        #if UNITY_STANDARD_SIMPLE
            half3 reflUVW;
        #endif

        #if UNITY_STANDARD_SIMPLE
            half3 tangentSpaceNormal;
        #endif

        float2 uvOffset; //时差uv偏移
        float4 blendValue;
    };

    // ------------------------------------------------------------------
    //  Base forward pass (directional light, emission, lightmaps, ...)

    struct VertexOutputForwardBase
    {
        UNITY_POSITION(pos);
        float4 tex                            : TEXCOORD0;
        float3 eyeVec                         : TEXCOORD1;
        float4 tangentToWorldAndPackedData[3] : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
        half4 ambientOrLightmapUV             : TEXCOORD5;    // SH or Lightmap UV
        UNITY_SHADOW_COORDS(6)
        UNITY_FOG_COORDS(7)

        // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
        #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
            float3 posWorld                 : TEXCOORD8;
        #endif

        float4 screenPos : TEXCOORD9;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };


    // ------------------------------------------------------------------
    //  Additive forward pass (one light per pass)

    struct VertexOutputForwardAdd
    {
        UNITY_POSITION(pos);
        float4 tex                          : TEXCOORD0;
        float3 eyeVec                       : TEXCOORD1;
        float4 tangentToWorldAndLightDir[3] : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:lightDir]
        float3 posWorld                     : TEXCOORD5;
        UNITY_SHADOW_COORDS(6)
        UNITY_FOG_COORDS(7)

        // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
        #if defined(_PARALLAXMAP)
            half3 viewDirForParallax            : TEXCOORD8;
        #endif

        float4 screenPos : TEXCOORD9;
        UNITY_VERTEX_OUTPUT_STEREO
    };


    // ------------------------------------------------------------------
    //  Deferred pass

    struct VertexOutputDeferred
    {
        UNITY_POSITION(pos);
        float4 tex                            : TEXCOORD0;
        float3 eyeVec                         : TEXCOORD1;
        float4 tangentToWorldAndPackedData[3] : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
        half4 ambientOrLightmapUV             : TEXCOORD5;    // SH or Lightmap UVs

        #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
            float3 posWorld                     : TEXCOORD6;
        #endif
        float4 screenPos : TEXCOORD9;

        UNITY_VERTEX_OUTPUT_STEREO
    };

    // Shadow
    float3 _ReceiveShadowColor;

    // Blend Property
    float4 _TintM,_TintR,_TintG,_TintB; // Color Mixed

    // UNITY_DECLARE_TEX2D(_MapM);
    // UNITY_DECLARE_TEX2D(_MapR);
    // UNITY_DECLARE_TEX2D(_MapG);
    // UNITY_DECLARE_TEX2D(_MapB);
    UNITY_DECLARE_TEX2D(_BlendTex);
    // //sampler2D _MapM,_MapR,_MapG,_MapB,_BlendTex; // Map And Normal And Hight
    UNITY_DECLARE_TEX2DARRAY(_MapArray);
    UNITY_DECLARE_TEX2DARRAY(_NormalArray);

    // UNITY_DECLARE_TEX2D(_MNormalMap);
    // UNITY_DECLARE_TEX2D(_RNormalMap);
    // UNITY_DECLARE_TEX2D(_GNormalMap);
    // UNITY_DECLARE_TEX2D(_BNormalMap);
    sampler2D _BlendNormalMap;
    //sampler2D _MNormalMap,_RNormalMap,_GNormalMap,_BNormalMap, _BlendNormalMap; // Normal Map 
    float _MBumpScale,_RBumpScale,_GBumpScale,_BBumpScale; // Map Normal Scale
    float _WorldScale; // Blend Scale
    float _MScale,_RScale,_GScale,_BScale; // Map Scale
    float _BlendNormalBumpScale;

    // Blend Item Get Depth Texture
    Texture2D _CameraDepthTexture;
    // SamplerState sampler_CameraDepthTexture;
    // UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture );
    // uniform float4 _CameraDepthTexture_TexelSize;
    float _BlendValue;
#endif