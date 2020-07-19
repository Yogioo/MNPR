
#include "UnityStandardConfig.cginc"

#ifndef NPR_STANDARD_CORE_INCLUDED
    #define NPR_STANDARD_CORE_INCLUDED

    #include "UnityCG.cginc"
    #include "UnityShaderVariables.cginc"
    #include "UnityInstancing.cginc"
    #include "UnityStandardConfig.cginc"
    #include "UnityStandardInput.cginc"
    #include "NPRPBSLighting.cginc"
    #include "UnityStandardUtils.cginc"
    #include "UnityGBuffer.cginc"
    #include "UnityStandardBRDF.cginc"
    #include "Property.cginc"

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
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData, IN_WORLDPOS(i));

    #define FRAGMENT_SETUP_FWDADD(x) FragmentCommonData x = \
    FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX_FWDADD(i), i.tangentToWorldAndLightDir, IN_WORLDPOS_FWDADD(i));



    #ifndef UNITY_SETUP_BRDF_INPUT
        #define UNITY_SETUP_BRDF_INPUT SpecularSetup
    #endif

    inline FragmentCommonData SpecularSetup (float4 i_tex)
    {
        half4 specGloss = SpecularGloss(i_tex.xy);
        half3 specColor = specGloss.rgb;
        half smoothness = specGloss.a;

        half oneMinusReflectivity;
        half3 diffColor = EnergyConservationBetweenDiffuseAndSpecular (Albedo(i_tex), specColor, /*out*/ oneMinusReflectivity);

        FragmentCommonData o = (FragmentCommonData)0;
        o.diffColor = diffColor;
        o.specColor = specColor;
        o.oneMinusReflectivity = oneMinusReflectivity;
        o.smoothness = smoothness;
        return o;
    }

    inline FragmentCommonData RoughnessSetup(float4 i_tex)
    {
        half2 metallicGloss = MetallicRough(i_tex.xy);
        half metallic = metallicGloss.x;
        half smoothness = metallicGloss.y; // this is 1 minus the square root of real roughness m.

        half oneMinusReflectivity;
        half3 specColor;
        half3 diffColor = DiffuseAndSpecularFromMetallic(Albedo(i_tex), metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

        FragmentCommonData o = (FragmentCommonData)0;
        o.diffColor = diffColor;
        o.specColor = specColor;
        o.oneMinusReflectivity = oneMinusReflectivity;
        o.smoothness = smoothness;
        return o;
    }

    inline FragmentCommonData MetallicSetup (float4 i_tex)
    {
        half2 metallicGloss = MetallicGloss(i_tex.xy);
        half metallic = metallicGloss.x;
        half smoothness = metallicGloss.y; // this is 1 minus the square root of real roughness m.

        half oneMinusReflectivity;
        half3 specColor;
        half3 diffColor = DiffuseAndSpecularFromMetallic (Albedo(i_tex), metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

        FragmentCommonData o = (FragmentCommonData)0;
        o.diffColor = diffColor;
        o.specColor = specColor;
        o.oneMinusReflectivity = oneMinusReflectivity;
        o.smoothness = smoothness;
        return o;
    }

    // parallax transformed texcoord is used to sample occlusion
    inline FragmentCommonData FragmentSetup (inout float4 i_tex, float3 i_eyeVec, half3 i_viewDirForParallax, float4 tangentToWorld[3], float3 i_posWorld)
    {
        i_tex = Parallax(i_tex, i_viewDirForParallax);

        half alpha = Alpha(i_tex.xy);
        #if defined(_ALPHATEST_ON)
            clip (alpha - _Cutoff);
        #endif

        FragmentCommonData o = UNITY_SETUP_BRDF_INPUT (i_tex);
        o.normalWorld = PerPixelWorldNormal(i_tex, tangentToWorld);
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


    // Main Physically Based BRDF
    // Derived from Disney work and based on Torrance-Sparrow micro-facet model
    //
    //   BRDF = kD / pi + kS * (D * V * F) / 4
    //   I = BRDF * NdotL
    //
    // * NDF (depending on UNITY_BRDF_GGX):
    //  a) Normalized BlinnPhong
    //  b) GGX
    // * Smith for Visiblity term
    // * Schlick approximation for Fresnel
    //#endregion
    half4 NPR_BRDF1_Unity_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
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

        float noneNormalizeNL = dot(normal, light.dir);
        float nl = saturate(noneNormalizeNL);
        float nh = saturate(dot(normal, halfDir));

        half lv = saturate(dot(light.dir, viewDir));
        half lh = saturate(dot(light.dir, halfDir));

        // Diffuse term
        half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;

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

        half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));
//return _LightColor0.rgbr * diffuseTerm ;
        // NPR Main
        // 1. 对Diffuse进行处理 控制暗面大小,颜色
        // 控制暗部的色彩渐变范围
        // 对漫反射光照值的暗部进行一个渐变处理, 否则是没有渐变  然后对暗部进行向暗部扩张行为
        float oneMinusdiffuseTerm = step(1,1-diffuseTerm); // 取得暗部
        //oneMinusdiffuseTerm = step(1,1-diffuseTerm); // 对暗部进行二值化
        oneMinusdiffuseTerm *= noneNormalizeNL; // 对暗部进行渐变
        oneMinusdiffuseTerm += diffuseTerm;
        _ShadowStrength-=5; // 方便材质面板调试 从最低-5 到0
        _ShadowFade-=0.499999; // 同上
        diffuseTerm = smoothstep(_ShadowStrength,_ShadowFade,oneMinusdiffuseTerm); // 跳转暗部范围

        // 包含接受的投影色
        float reciveShadowTerm = 1-step(.1,light.color.r+light.color.g+light.color.b);
        float3 reciveShadowColor = nl*reciveShadowTerm * _ReceiveShadowColor +1- nl*reciveShadowTerm;
        // 取得漫反射暗面
        float shadowTerm = 1- diffuseTerm;
        float3 shadowColor = shadowTerm * _ShadowColor + 1-shadowTerm;
        
        // 2. 明暗交界线加深 叠加在亮面上面  4.8 0.7  _MiddleLineWidth
        float width = smoothstep(0,1,diffuseTerm) ; // 跳转暗部范围
        float width2 = smoothstep(_MiddleLineWidth,1,diffuseTerm);
        float widthLine = saturate(( width - width2) *  _MiddleLineStrength); // 明暗交接线
        float3 lineTTT = widthLine * _MiddleLineColor + 1 - widthLine ;
        

         // 固有色 *(全局光照 + 灯光色 * 漫反射 + 阴影 + 投影)  问题: 灯光色中不应该包含了阴影
        half3 color =   diffColor * (gi.diffuse + _LightColor0.rgb  * shadowColor * reciveShadowColor * lineTTT) // 漫反射  根据全局光照 灯光颜色 模型贴图 决定色彩,参数为迪士尼brdf经验模型
        + specularTerm * light.color * FresnelTerm (specColor, lh) // 反射 根据金属度与光滑度决定反射效果, 反射色为灯光颜色
        + surfaceReduction * gi.specular * FresnelLerp (specColor, grazingTerm, nv) // 反射天空采样 色彩根据天空球(probe) 反射颜色(金属反射本身)  ,参数根据粗糙程度
        //+ oneMinusDiffuseTerm * shadowCol // 阴影色
        ; 
        
        
        //color = gi.diffuse + _LightColor0.rgb  * shadowColor * reciveShadowColor + lineTTT;
        //color =  (width - width2);
        return half4(color, 1);
    }
    
    //-----------------------------Forward Render--------------------------------------------------------

    VertexOutputForwardBase vertForwardBase (VertexInput v)
    {
        UNITY_SETUP_INSTANCE_ID(v);
        VertexOutputForwardBase o;
        UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase, o);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
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

        half4 c = NPR_BRDF1_Unity_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
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

        half4 c = NPR_BRDF1_Unity_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect);

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

        half3 emissiveColor = NPR_BRDF1_Unity_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect).rgb;

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
