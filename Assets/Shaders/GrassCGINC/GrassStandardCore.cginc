
#include "UnityStandardConfig.cginc"

#ifndef GRASS_STANDARD_CORE
    #define GRASS_STANDARD_CORE

    #include "UnityCG.cginc"
    #include "UnityShaderVariables.cginc"
    #include "UnityInstancing.cginc"
    #include "UnityStandardConfig.cginc"
    #include "UnityStandardInput.cginc"
    #include "UnityStandardUtils.cginc"
    #include "UnityGBuffer.cginc"
    #include "UnityStandardBRDF.cginc"
    #include "GrassProperty.cginc"

    #include "AutoLight.cginc"
    //-------------------------------------------------------------------------------------
    // counterpart for NormalizePerPixelNormal
    // skips normalization per-vertex and expects normalization to happen per-pixel
    half3 NormalizePerVertexNormal (float3 n) // takes float to avoid overflow
    {
        #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
            return normalize(n);
        #else
            return n; // will normalize per-pixel instead
        #endif
    }

    float3 NormalizePerPixelNormal (float3 n)
    {
        #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
            return n;
        #else
            return normalize(n);
        #endif
    }

    //-------------------------------------------------------------------------------------
    UnityLight MainLight ()
    {
        UnityLight l;

        l.color = _LightColor0.rgb;
        l.dir = _WorldSpaceLightPos0.xyz;
        return l;
    }

    UnityLight AdditiveLight (half3 lightDir, half atten)
    {
        UnityLight l;

        l.color = _LightColor0.rgb;
        l.dir = lightDir;
        #ifndef USING_DIRECTIONAL_LIGHT
            l.dir = NormalizePerPixelNormal(l.dir);
        #endif

        // shadow the light
        l.color *= atten;
        return l;
    }

    UnityLight DummyLight ()
    {
        UnityLight l;
        l.color = 0;
        l.dir = half3 (0,1,0);
        return l;
    }

    UnityIndirect ZeroIndirect ()
    {
        UnityIndirect ind;
        ind.diffuse = 0;
        ind.specular = 0;
        return ind;
    }

    //-------------------------------------------------------------------------------------
    // Common fragment setup

    // deprecated
    half3 WorldNormal(half4 tan2world[3])
    {
        return normalize(tan2world[2].xyz);
    }

    // deprecated
    #ifdef _TANGENT_TO_WORLD
        half3x3 ExtractTangentToWorldPerPixel(half4 tan2world[3])
        {
            half3 t = tan2world[0].xyz;
            half3 b = tan2world[1].xyz;
            half3 n = tan2world[2].xyz;

            #if UNITY_TANGENT_ORTHONORMALIZE
                n = NormalizePerPixelNormal(n);

                // ortho-normalize Tangent
                t = normalize (t - n * dot(t, n));

                // recalculate Binormal
                half3 newB = cross(n, t);
                b = newB * sign (dot (newB, b));
            #endif

            return half3x3(t, b, n);
        }
    #else
        half3x3 ExtractTangentToWorldPerPixel(half4 tan2world[3])
        {
            return half3x3(0,0,0,0,0,0,0,0,0);
        }
    #endif

    float3 PerPixelWorldNormal(float4 i_tex, float4 tangentToWorld[3])
    {
        #ifdef _NORMALMAP
            half3 tangent = tangentToWorld[0].xyz;
            half3 binormal = tangentToWorld[1].xyz;
            half3 normal = tangentToWorld[2].xyz;

            #if UNITY_TANGENT_ORTHONORMALIZE
                normal = NormalizePerPixelNormal(normal);

                // ortho-normalize Tangent
                tangent = normalize (tangent - normal * dot(tangent, normal));

                // recalculate Binormal
                half3 newB = cross(normal, tangent);
                binormal = newB * sign (dot (newB, binormal));
            #endif

            half3 normalTangent = NormalInTangentSpace(i_tex);
            float3 normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
        #else
            float3 normalWorld = normalize(tangentToWorld[2].xyz);
        #endif
        return normalWorld;
    }

    #ifdef _PARALLAXMAP
        #define IN_VIEWDIR4PARALLAX(i) NormalizePerPixelNormal(half3(i.tangentToWorldAndPackedData[0].w,i.tangentToWorldAndPackedData[1].w,i.tangentToWorldAndPackedData[2].w))
        #define IN_VIEWDIR4PARALLAX_FWDADD(i) NormalizePerPixelNormal(i.viewDirForParallax.xyz)
    #else
        #define IN_VIEWDIR4PARALLAX(i) half3(0,0,0)
        #define IN_VIEWDIR4PARALLAX_FWDADD(i) half3(0,0,0)
    #endif

    #if UNITY_REQUIRE_FRAG_WORLDPOS
        #if UNITY_PACK_WORLDPOS_WITH_TANGENT
            #define IN_WORLDPOS(i) half3(i.tangentToWorldAndPackedData[0].w,i.tangentToWorldAndPackedData[1].w,i.tangentToWorldAndPackedData[2].w)
        #else
            #define IN_WORLDPOS(i) i.posWorld
        #endif
        #define IN_WORLDPOS_FWDADD(i) i.posWorld
    #else
        #define IN_WORLDPOS(i) half3(0,0,0)
        #define IN_WORLDPOS_FWDADD(i) half3(0,0,0)
    #endif

    #define IN_LIGHTDIR_FWDADD(i) half3(i.tangentToWorldAndLightDir[0].w, i.tangentToWorldAndLightDir[1].w, i.tangentToWorldAndLightDir[2].w)

    #define FRAGMENT_SETUP(x) FragmentCommonData x = \
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData, IN_WORLDPOS(i),i.screenPos);

    #define FRAGMENT_SETUP_FWDADD(x) FragmentCommonData x = \
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX_FWDADD(i), i.tangentToWorldAndLightDir, IN_WORLDPOS_FWDADD(i),i.screenPos);


    half3 Albedo2(float4 texcoords,float3 worldPos,float4 blendValue,float4 screenPos)
    {
        half3 origionAlbedo = _Color.rgb *   tex2D (_MainTex, texcoords.xy).rgb;
        //#region Mix All Map 
        //-------------------------Mix All Map Start-----------------------------------------
        // // Blend Item 
        // _BlendValue = 15-_BlendValue;
        // half3 distanceDepth = saturate(worldPos.y*_BlendValue);

        // Blend Item 
        // screenPos = float4(screenPos.xyz,screenPos.w+0.00000000001);
        // float4 screenPosNor = screenPos/screenPos.w;
        // screenPosNor.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? screenPosNor.z : screenPosNor.z * 0.5 + 0.5;
        // float screenDepth = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD( screenPos ))));
        // float distanceDepth = abs( ( screenDepth - (LinearEyeDepth( screenPosNor.z )) ) / ( _BlendValue ) );
        // distanceDepth = clamp(distanceDepth,0,1);
        float distanceDepth = saturate( worldPos.y*_BlendValue);
        
        float2 mUV = worldPos.xz * _MScale;
        float2 rUV = worldPos.xz * _RScale;
        float2 gUV = worldPos.xz * _GScale;
        float2 bUV = worldPos.xz * _BScale;
        float2 blendUV = worldPos.xz * _WorldScale ;

        
        half3 m = UNITY_SAMPLE_TEX2DARRAY(_MapArray,float3(mUV,0))*_TintM;
        half3 r = UNITY_SAMPLE_TEX2DARRAY(_MapArray,float3(rUV,0))*_TintR;
        half3 g = UNITY_SAMPLE_TEX2DARRAY(_MapArray,float3(gUV,0))*_TintG;
        half3 b = UNITY_SAMPLE_TEX2DARRAY(_MapArray,float3(bUV,0))*_TintB;

        
        // Blend Ground Albedo Value
        half3 finalAlbedo = lerp(m,r,blendValue.r);//albedoR + albedoG + albedoB + albedo*bO;
        finalAlbedo = lerp(finalAlbedo,g,blendValue.g);//albedoR + albedoG + albedoB + albedo*bO;
        finalAlbedo = lerp(finalAlbedo,b,blendValue.b);//albedoR + albedoG + albedoB + albedo*bO;
        
        finalAlbedo = lerp(finalAlbedo,origionAlbedo,distanceDepth);
        // float3 finalAlbedo = blendValue.r*r+blendValue.g *g +blendValue.b*b + m*blendValue.a;
        //finalAlbedo = distanceDepth;

        //-------------------------Mix All Map Over-------------------------------------------
        //#endregion

        // half3 albedo =  _Color.rgb * tex2D (_MainTex, texcoords.xy).rgb;
        //albedo = tex2D(_MapM,mUV + texcoords.xy);
        #if _DETAIL
            #if (SHADER_TARGET < 30)
                // SM20: instruction count limitation
                // SM20: no detail mask
                half mask = 1;
            #else
                half mask = DetailMask(texcoords.xy);
            #endif
            half3 detailAlbedo = tex2D (_DetailAlbedoMap, texcoords.zw).rgb;
            #if _DETAIL_MULX2
                finalAlbedo *= LerpWhiteTo (detailAlbedo * unity_ColorSpaceDouble.rgb, mask);
            #elif _DETAIL_MUL
                finalAlbedo *= LerpWhiteTo (detailAlbedo, mask);
            #elif _DETAIL_ADD
                finalAlbedo += detailAlbedo * mask;
            #elif _DETAIL_LERP
                finalAlbedo = lerp (finalAlbedo, detailAlbedo, mask);
            #endif
        #endif
        return finalAlbedo;// LinearEyeDepth( screenPosNor.z );
    }

    #ifndef UNITY_SETUP_BRDF_INPUT
        #define UNITY_SETUP_BRDF_INPUT SpecularSetup
    #endif

    inline FragmentCommonData MetallicSetup (float4 i_tex,float3 worldPos,float4 screenPos,float4 blendValue)
    {



        half2 metallicGloss = MetallicGloss(i_tex.xy);
        half metallic = metallicGloss.x;
        half smoothness = metallicGloss.y; // this is 1 minus the square root of real roughness m.

        half oneMinusReflectivity;
        half3 specColor;
        half3 diffColor = DiffuseAndSpecularFromMetallic (Albedo2(i_tex,worldPos,blendValue,screenPos), metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

        FragmentCommonData o = (FragmentCommonData)0;
        o.diffColor = diffColor;
        o.specColor = specColor;
        o.oneMinusReflectivity = oneMinusReflectivity;
        o.smoothness = smoothness;
        return o;
    }

    float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
        return cross(normal, tangent.xyz) *
        (binormalSign * unity_WorldTransformParams.w);
    }


    float3 GetNormal(float2 uv,sampler2D normalMap,float bumpScale){
        float3 norm = float3(0,1,0);
        float3 tang = float3(0,0,1);
        float3 binormal = float3(1,0,0);
        float3 tangentSpaceNormal = UnpackScaleNormal(tex2D(normalMap, uv), bumpScale);
        return normalize(
        tangentSpaceNormal.x * tang +
        tangentSpaceNormal.y * binormal +
        tangentSpaceNormal.z * norm
        );
    }

    // parallax transformed texcoord is used to sample occlusion
    inline FragmentCommonData FragmentSetup (inout float4 i_tex, float3 i_eyeVec, half3 i_viewDirForParallax, float4 tangentToWorld[3], float3 i_posWorld,float4 screenPos)
    {
        //-------------------------Mix All Map Start-----------------------------------------
        
        float2 mUV = i_posWorld.xz * _MScale;
        float2 rUV = i_posWorld.xz * _RScale;
        float2 gUV = i_posWorld.xz * _GScale;
        float2 bUV = i_posWorld.xz * _BScale;
        float2 blendUV = i_posWorld.xz * _WorldScale ;
        
        float3 blendMap = tex2D(_BlendTex,blendUV);
        float bR = blendMap.r;
        float bG = blendMap.g;
        float bB = blendMap.b;
        float bM =max(0,1-bR-bG-bB);

        float4 blendValue = float4(bR,bG,bB,bM);
        //o.blendValue = blendValue;
        //-------------------------Mix All Map Over-------------------------------------------


        i_tex = Parallax(i_tex, i_viewDirForParallax);

        half alpha = Alpha(i_tex.xy);
        #if defined(_ALPHATEST_ON)
            clip (alpha - _Cutoff);
        #endif


        FragmentCommonData o = MetallicSetup (i_tex,i_posWorld,screenPos,blendValue);
        o.normalWorld = PerPixelWorldNormal(i_tex, tangentToWorld);
        //------------------------- Mix All Normal Start -------------------------

        // // mix normal
        
        // float3 mN = GetNormal(mUV,_MNormalMap,_MBumpScale);
        // float3 rN = GetNormal(rUV,_RNormalMap,_RBumpScale);
        // float3 gN = GetNormal(gUV,_GNormalMap,_GBumpScale);
        // float3 bN = GetNormal(bUV,_BNormalMap,_BBumpScale);
        // float3 n1 = GetNormal(blendUV,_BlendNormalMap,_BlendNormalBumpScale);

        // float3 finalWorldNormal;
        // float3 resultNormal;
        // float3 n2 =  normalize(rN*blendValue.r+gN *blendValue.g +bN*blendValue.b + mN*blendValue.a);
        // resultNormal = (n1+n2)/2;
        // o.normalWorld = resultNormal;

        //------------------------- Mix All Normal Over -------------------------
        o.eyeVec = NormalizePerPixelNormal(i_eyeVec);
        o.posWorld = i_posWorld;

        // NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
        o.diffColor = PreMultiplyAlpha (o.diffColor, alpha, o.oneMinusReflectivity, /*out*/ o.alpha);
        return o;
    }

    inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light, bool reflections)
    {
        UnityGIInput d;
        d.light = light;
        d.worldPos = s.posWorld;
        d.worldViewDir = -s.eyeVec;
        d.atten = atten;
        #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
            d.ambient = 0;
            d.lightmapUV = i_ambientOrLightmapUV;
        #else
            d.ambient = i_ambientOrLightmapUV.rgb;
            d.lightmapUV = 0;
        #endif

        d.probeHDR[0] = unity_SpecCube0_HDR;
        d.probeHDR[1] = unity_SpecCube1_HDR;
        #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
            d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
        #endif
        #ifdef UNITY_SPECCUBE_BOX_PROJECTION
            d.boxMax[0] = unity_SpecCube0_BoxMax;
            d.probePosition[0] = unity_SpecCube0_ProbePosition;
            d.boxMax[1] = unity_SpecCube1_BoxMax;
            d.boxMin[1] = unity_SpecCube1_BoxMin;
            d.probePosition[1] = unity_SpecCube1_ProbePosition;
        #endif

        if(reflections)
        {
            Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.smoothness, -s.eyeVec, s.normalWorld, s.specColor);
            // Replace the reflUVW if it has been compute in Vertex shader. Note: the compiler will optimize the calcul in UnityGlossyEnvironmentSetup itself
            #if UNITY_STANDARD_SIMPLE
                g.reflUVW = s.reflUVW;
            #endif

            return UnityGlobalIllumination (d, occlusion, s.normalWorld, g);
        }
        else
        {
            return UnityGlobalIllumination (d, occlusion, s.normalWorld);
        }
    }

    inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light)
    {
        return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, true);
    }


    //-------------------------------------------------------------------------------------
    half4 OutputForward (half4 output, half alphaFromSurface)
    {
        #if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
            output.a = alphaFromSurface;
        #else
            UNITY_OPAQUE_ALPHA(output.a);
        #endif
        return output;
    }

    inline half4 VertexGIForward(VertexInput v, float3 posWorld, half3 normalWorld)
    {
        half4 ambientOrLightmapUV = 0;
        // Static lightmaps
        #ifdef LIGHTMAP_ON
            ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
            ambientOrLightmapUV.zw = 0;
            // Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
        #elif UNITY_SHOULD_SAMPLE_SH
            #ifdef VERTEXLIGHT_ON
                // Approximated illumination from non-important point lights
                ambientOrLightmapUV.rgb = Shade4PointLights (
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, posWorld, normalWorld);
            #endif

            ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);
        #endif

        #ifdef DYNAMICLIGHTMAP_ON
            ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
        #endif

        return ambientOrLightmapUV;
    }
    
    //------------------------------BRDF-------------------------------------------------------
    //#region BRDF Des
    // Note: BRDF entry points use smoothness and oneMinusReflectivity for optimization
    // purposes, mostly for DX9 SM2.0 level. Most of the math is being done on these (1-x) values, and that saves
    // a few precious ALU slots.


    half4 Grass_BRDF1_Unity_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
    float3 normal, float3 viewDir,
    UnityLight light, UnityIndirect gi)
    {
        float perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
        float3 halfDir = Unity_SafeNormalize (float3(light.dir) + viewDir);

        // NdotV should not be negative for visible pixels, but it can happen due to perspective projection and normal mapping
        // In this case normal should be modified to become valid (i.e facing camera) and not cause weird artifacts.
        // but this operation adds few ALU and users may not want it. Alternative is to simply take the abs of NdotV (less correct but works too).
        // Following define allow to control this. Set it to 0 if ALU is critical on your platform.
        // This correction is interesting for GGX with SmithJoint visibility function because artifacts are more visible in this case due to highlight edge of rough surface
        // Edit: Disable this code by default for now as it is not compatible with two sided lighting used in SpeedTree.
        #define UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV 0

        #if UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV
            // The amount we shift the normal toward the view vector is defined by the dot product.
            half shiftAmount = dot(normal, viewDir);
            normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;
            // A re-normalization should be applied here but as the shift is small we don't do it to save ALU.
            //normal = normalize(normal);

            float nv = saturate(dot(normal, viewDir)); // TODO: this saturate should no be necessary here
        #else
            half nv = abs(dot(normal, viewDir));    // This abs allow to limit artifact
        #endif

        float nl = saturate(dot(normal, light.dir));
        float nh = saturate(dot(normal, halfDir));

        half lv = saturate(dot(light.dir, viewDir));
        half lh = saturate(dot(light.dir, halfDir));

        // Diffuse term
        //half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;

        // Specular term
        // HACK: theoretically we should divide diffuseTerm by Pi and not multiply specularTerm!
        // BUT 1) that will make shader look significantly darker than Legacy ones
        // and 2) on engine side "Non-important" lights have to be divided by Pi too in cases when they are injected into ambient SH
        float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
        #if UNITY_BRDF_GGX
            // GGX with roughtness to 0 would mean no specular at all, using max(roughness, 0.002) here to match HDrenderloop roughtness remapping.
            roughness = max(roughness, 0.002);
            float V = SmithJointGGXVisibilityTerm (nl, nv, roughness);
            float D = GGXTerm (nh, roughness);
        #else
            // Legacy
            half V = SmithBeckmannVisibilityTerm (nl, nv, roughness);
            half D = NDFBlinnPhongNormalizedTerm (nh, PerceptualRoughnessToSpecPower(perceptualRoughness));
        #endif

        float specularTerm = V*D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later

        #   ifdef UNITY_COLORSPACE_GAMMA
        specularTerm = sqrt(max(1e-4h, specularTerm));
        #   endif

        // specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
        specularTerm = max(0, specularTerm * nl);
        #if defined(_SPECULARHIGHLIGHTS_OFF)
            specularTerm = 0.0;
        #endif

        // surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
        half surfaceReduction;
        #   ifdef UNITY_COLORSPACE_GAMMA
        surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
        #   else
        surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
        #   endif

        // To provide true Lambert lighting, we need to be able to kill specular completely.
        specularTerm *= any(specColor) ? 1.0 : 0.0;

        // 包含接受的投影色
        float reciveShadowTerm = (1-light.color);//1-step(.1,light.color.r+light.color.g+light.color.b);
        float3 reciveShadowColor = reciveShadowTerm * _ReceiveShadowColor +1- reciveShadowTerm;

        half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));
        half3 color =   diffColor * (gi.diffuse + _LightColor0.rgb * reciveShadowColor);//diffuseTerm) //草地不需要漫反射,通过贴图绘制
        + specularTerm * light.color * FresnelTerm (specColor, lh)
        + surfaceReduction * gi.specular * FresnelLerp (specColor, grazingTerm, nv);

        //color = _LightColor0.rgb* (reciveShadowTerm*float3(1,0,0) + (1-reciveShadowTerm) );
        //color = reciveShadowColor;
        return half4(color, 1);
    }
    
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

    //-----------------------------Forward Render--------------------------------------------------------

    VertexOutputForwardBase vertForwardBase (VertexInput v)
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
        posWorld = lerp(posWorld,newWorldPos,v.uv0.y);

        // Interactive Grass Movement
        for (int n = 0; n<_PositionArrayCount;n++){
            float2 dir =  OriginPosWorld.xz - _ObstaclePositions[n].xz;
            float dirLength = length(dir);
            dirLength =_InteractiveRange-clamp(dirLength,0,_InteractiveRange); // Clamp踩草长度
            float2 value=  dirLength * dir * v.uv0.y;
            value = clamp(value,-_InteractiveStrength,_InteractiveStrength);
            posWorld.xz += value;
            posWorld.y -=abs(value);
        }

        v.vertex =  mul(unity_WorldToObject,posWorld);


        // -----------------Grass Vertex Movement Over-----------------

        UNITY_SETUP_INSTANCE_ID(v);
        VertexOutputForwardBase o;
        UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase, o);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        
        posWorld = mul(unity_ObjectToWorld, v.vertex);

        #if UNITY_REQUIRE_FRAG_WORLDPOS
            #if UNITY_PACK_WORLDPOS_WITH_TANGENT
                o.tangentToWorldAndPackedData[0].w = posWorld.x;
                o.tangentToWorldAndPackedData[1].w = posWorld.y;
                o.tangentToWorldAndPackedData[2].w = posWorld.z;
            #else
                o.posWorld = posWorld.xyz;
            #endif
        #endif
        o.pos = UnityObjectToClipPos(v.vertex);

        o.tex = TexCoords(v);
        o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
        float3 normalWorld = UnityObjectToWorldNormal(v.normal);
        #ifdef _TANGENT_TO_WORLD
            float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

            float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
            o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
            o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
            o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
        #else
            o.tangentToWorldAndPackedData[0].xyz = 0;
            o.tangentToWorldAndPackedData[1].xyz = 0;
            o.tangentToWorldAndPackedData[2].xyz = normalWorld;
        #endif

        //We need this for shadow receving
        UNITY_TRANSFER_SHADOW(o, v.uv1);

        o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);

        #ifdef _PARALLAXMAP
            TANGENT_SPACE_ROTATION;
            half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
            o.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
            o.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
            o.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
        #endif

        UNITY_TRANSFER_FOG(o,o.pos);

        o.screenPos =ComputeScreenPos(o.pos);
        
        return o;
    }

    half4 fragForwardBaseInternal (VertexOutputForwardBase i)
    {
        UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

        FRAGMENT_SETUP(s)

        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

        UnityLight mainLight = MainLight ();
        UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);

        half occlusion = Occlusion(i.tex.xy);
        UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

        half4 c = Grass_BRDF1_Unity_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
        c.rgb += Emission(i.tex.xy);
        

        UNITY_APPLY_FOG(i.fogCoord, c.rgb);

        return OutputForward (c, s.alpha);
    }
    // Entry Vertex 
    VertexOutputForwardBase vertBase (VertexInput v) {        
        return vertForwardBase(v);     
    }
    // Entry Fragment
    half4 fragBase (VertexOutputForwardBase i) : SV_TARGET{
        return fragForwardBaseInternal(i);    
    }

    
    //-----------------------------Forward Add Render--------------------------------------------------------
    
    VertexOutputForwardAdd vertForwardAdd (VertexInput v)
    {
        UNITY_SETUP_INSTANCE_ID(v);
        VertexOutputForwardAdd o;
        UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAdd, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
        o.pos = UnityObjectToClipPos(v.vertex);

        o.tex = TexCoords(v);
        o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
        o.posWorld = posWorld.xyz;
        float3 normalWorld = UnityObjectToWorldNormal(v.normal);
        #ifdef _TANGENT_TO_WORLD
            float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

            float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
            o.tangentToWorldAndLightDir[0].xyz = tangentToWorld[0];
            o.tangentToWorldAndLightDir[1].xyz = tangentToWorld[1];
            o.tangentToWorldAndLightDir[2].xyz = tangentToWorld[2];
        #else
            o.tangentToWorldAndLightDir[0].xyz = 0;
            o.tangentToWorldAndLightDir[1].xyz = 0;
            o.tangentToWorldAndLightDir[2].xyz = normalWorld;
        #endif
        //We need this for shadow receiving
        UNITY_TRANSFER_SHADOW(o, v.uv1);

        float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
        #ifndef USING_DIRECTIONAL_LIGHT
            lightDir = NormalizePerVertexNormal(lightDir);
        #endif
        o.tangentToWorldAndLightDir[0].w = lightDir.x;
        o.tangentToWorldAndLightDir[1].w = lightDir.y;
        o.tangentToWorldAndLightDir[2].w = lightDir.z;

        #ifdef _PARALLAXMAP
            TANGENT_SPACE_ROTATION;
            o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
        #endif

        UNITY_TRANSFER_FOG(o,o.pos);
        return o;
    }

    half4 fragForwardAddInternal (VertexOutputForwardAdd i)
    {
        UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

        FRAGMENT_SETUP_FWDADD(s)

        UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld)
        UnityLight light = AdditiveLight (IN_LIGHTDIR_FWDADD(i), atten);
        UnityIndirect noIndirect = ZeroIndirect ();

        half4 c = Grass_BRDF1_Unity_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect);

        UNITY_APPLY_FOG_COLOR(i.fogCoord, c.rgb, half4(0,0,0,0)); // fog towards black in additive pass
        return OutputForward (c, s.alpha);
    }

    // Entry Vertex 
    VertexOutputForwardAdd vertAdd (VertexInput v) 
    { 
        return vertForwardAdd(v); 
    }
    // Entry Fragment
    half4 fragAdd (VertexOutputForwardAdd i) : SV_Target     // backward compatibility (this used to be the fragment entry function)
    {
        return fragForwardAddInternal(i);
    }



    //-----------------------------Deferred Add Render--------------------------------------------------------

    VertexOutputDeferred vertDeferred (VertexInput v)
    {
        UNITY_SETUP_INSTANCE_ID(v);
        VertexOutputDeferred o;
        UNITY_INITIALIZE_OUTPUT(VertexOutputDeferred, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

        float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
        #if UNITY_REQUIRE_FRAG_WORLDPOS
            #if UNITY_PACK_WORLDPOS_WITH_TANGENT
                o.tangentToWorldAndPackedData[0].w = posWorld.x;
                o.tangentToWorldAndPackedData[1].w = posWorld.y;
                o.tangentToWorldAndPackedData[2].w = posWorld.z;
            #else
                o.posWorld = posWorld.xyz;
            #endif
        #endif
        o.pos = UnityObjectToClipPos(v.vertex);

        o.tex = TexCoords(v);
        o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
        float3 normalWorld = UnityObjectToWorldNormal(v.normal);
        #ifdef _TANGENT_TO_WORLD
            float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

            float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
            o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
            o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
            o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
        #else
            o.tangentToWorldAndPackedData[0].xyz = 0;
            o.tangentToWorldAndPackedData[1].xyz = 0;
            o.tangentToWorldAndPackedData[2].xyz = normalWorld;
        #endif

        o.ambientOrLightmapUV = 0;
        #ifdef LIGHTMAP_ON
            o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        #elif UNITY_SHOULD_SAMPLE_SH
            o.ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, o.ambientOrLightmapUV.rgb);
        #endif
        #ifdef DYNAMICLIGHTMAP_ON
            o.ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
        #endif

        #ifdef _PARALLAXMAP
            TANGENT_SPACE_ROTATION;
            half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
            o.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
            o.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
            o.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
        #endif

        return o;
    }

    void fragDeferred (
    VertexOutputDeferred i,
    out half4 outGBuffer0 : SV_Target0,
    out half4 outGBuffer1 : SV_Target1,
    out half4 outGBuffer2 : SV_Target2,
    out half4 outEmission : SV_Target3          // RT3: emission (rgb), --unused-- (a)
    #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
        ,out half4 outShadowMask : SV_Target4       // RT4: shadowmask (rgba)
    #endif
    )
    {
        #if (SHADER_TARGET < 30)
            outGBuffer0 = 1;
            outGBuffer1 = 1;
            outGBuffer2 = 0;
            outEmission = 0;
            #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
                outShadowMask = 1;
            #endif
            return;
        #endif

        UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

        FRAGMENT_SETUP(s)

        // no analytic lights in this pass
        UnityLight dummyLight = DummyLight ();
        half atten = 1;

        // only GI
        half occlusion = Occlusion(i.tex.xy);
        #if UNITY_ENABLE_REFLECTION_BUFFERS
            bool sampleReflectionsInDeferred = false;
        #else
            bool sampleReflectionsInDeferred = true;
        #endif

        UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, dummyLight, sampleReflectionsInDeferred);

        half3 emissiveColor = Grass_BRDF1_Unity_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect).rgb;

        #ifdef _EMISSION
            emissiveColor += Emission (i.tex.xy);
        #endif

        #ifndef UNITY_HDR_ON
            emissiveColor.rgb = exp2(-emissiveColor.rgb);
        #endif

        UnityStandardData data;
        data.diffuseColor   = s.diffColor;
        data.occlusion      = occlusion;
        data.specularColor  = s.specColor;
        data.smoothness     = s.smoothness;
        data.normalWorld    = s.normalWorld;

        UnityStandardDataToGbuffer(data, outGBuffer0, outGBuffer1, outGBuffer2);

        // Emissive lighting buffer
        outEmission = half4(emissiveColor, 1);

        // Baked direct lighting occlusion if any
        #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
            outShadowMask = UnityGetRawBakedOcclusions(i.ambientOrLightmapUV.xy, IN_WORLDPOS(i));
        #endif
    }


    //
    // Old FragmentGI signature. Kept only for backward compatibility and will be removed soon
    //

    inline UnityGI FragmentGI(
    float3 posWorld,
    half occlusion, half4 i_ambientOrLightmapUV, half atten, half smoothness, half3 normalWorld, half3 eyeVec,
    UnityLight light,
    bool reflections)
    {
        // we init only fields actually used
        FragmentCommonData s = (FragmentCommonData)0;
        s.smoothness = smoothness;
        s.normalWorld = normalWorld;
        s.eyeVec = eyeVec;
        s.posWorld = posWorld;
        return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, reflections);
    }
    inline UnityGI FragmentGI (
    float3 posWorld,
    half occlusion, half4 i_ambientOrLightmapUV, half atten, half smoothness, half3 normalWorld, half3 eyeVec,
    UnityLight light)
    {
        return FragmentGI (posWorld, occlusion, i_ambientOrLightmapUV, atten, smoothness, normalWorld, eyeVec, light, true);
    }

#endif // UNITY_STANDARD_CORE_INCLUDED
