#ifndef PROPERTY_DEF
    #define PROPERTY_DEF

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

        UNITY_VERTEX_OUTPUT_STEREO
    };

    float3 _ShadowColor,_ReceiveShadowColor,_MiddleLineColor,_FresnelColor;
    float _ShadowStrength,_MiddleLineStrength;
    float _FresnelStrength;
#endif