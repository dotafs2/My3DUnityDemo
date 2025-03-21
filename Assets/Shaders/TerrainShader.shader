Shader "FSShader/URP Toon Terrain Compatible"
{
    Properties
    {
        // 基础颜色和纹理
        [Header(Base Terrain)]
        _Color("Base Color", Color) = (0.5, 0.65, 1, 1)
        [NoScaleOffset] _MainTex("Terrain Base Texture (RGB)", 2D) = "white" {}
        [NoScaleOffset] _NormalMap("Terrain Normal Map", 2D) = "bump" {}
        
        // 纹理混合贴图
        [Header(Texture Blending)]
        [NoScaleOffset] _SplatMap("Splat Control Map (RGBA)", 2D) = "black" {}
        
        // 细节层纹理
        [Header(Terrain Layers)]
        [NoScaleOffset] _Splat0("Layer 1 (R)", 2D) = "white" {}
        [NoScaleOffset] _Splat1("Layer 2 (G)", 2D) = "white" {}
        [NoScaleOffset] _Splat2("Layer 3 (B)", 2D) = "white" {}
        [NoScaleOffset] _Splat3("Layer 4 (A)", 2D) = "white" {}
        
        [Header(Layer Normal Maps)]
        [NoScaleOffset] _Normal0("Layer 1 Normal", 2D) = "bump" {}
        [NoScaleOffset] _Normal1("Layer 2 Normal", 2D) = "bump" {}
        [NoScaleOffset] _Normal2("Layer 3 Normal", 2D) = "bump" {}
        [NoScaleOffset] _Normal3("Layer 4 Normal", 2D) = "bump" {}
        
        // 纹理缩放
        [Header(Tiling)]
        _Tiling("Layer Tiling", Vector) = (1, 1, 1, 1)
        
        // 卡通渲染参数
        [Header(Toon Lighting)]
        [HDR] _AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)
        [HDR] _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
        _Glossiness("Glossiness", Float) = 32
        [HDR] _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1
        _ToonRamp("Toon Ramp Threshold", Range(0, 1)) = 0.5
        _SmoothAmount("Smooth Amount", Range(0, 0.5)) = 0.01
    }
    
    SubShader
    {
        Tags { 
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry-100"
            "TerrainCompatible" = "True"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : NORMAL;
                float3 tangentWS    : TEXCOORD3;
                float3 bitangentWS  : TEXCOORD4;
                float3 viewDirWS    : TEXCOORD1;
                float4 shadowCoord  : TEXCOORD2;
            };
            
            // 基础纹理
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            
            // 混合控制图
            TEXTURE2D(_SplatMap);
            SAMPLER(sampler_SplatMap);
            
            // 层纹理
            TEXTURE2D(_Splat0);
            SAMPLER(sampler_Splat0);
            TEXTURE2D(_Splat1);
            SAMPLER(sampler_Splat1);
            TEXTURE2D(_Splat2);
            SAMPLER(sampler_Splat2);
            TEXTURE2D(_Splat3);
            SAMPLER(sampler_Splat3);
            
            // 层法线贴图
            TEXTURE2D(_Normal0);
            SAMPLER(sampler_Normal0);
            TEXTURE2D(_Normal1);
            SAMPLER(sampler_Normal1);
            TEXTURE2D(_Normal2);
            SAMPLER(sampler_Normal2);
            TEXTURE2D(_Normal3);
            SAMPLER(sampler_Normal3);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
                float4 _AmbientColor;
                float _Glossiness;
                float4 _SpecularColor;
                float4 _RimColor;
                float _RimAmount;
                float _RimThreshold;
                float _ToonRamp;
                float _SmoothAmount;
                float4 _Tiling;
            CBUFFER_END
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                // 计算切线空间到世界空间的变换矩阵
                output.tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
                output.bitangentWS = cross(output.normalWS, output.tangentWS) * input.tangentOS.w;
                
                output.viewDirWS = GetWorldSpaceViewDir(TransformObjectToWorld(input.positionOS.xyz));
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.shadowCoord = GetShadowCoord(vertexInput);
                
                return output;
            }
            
            // 从法线贴图中获取世界空间法线
            float3 GetNormalFromMap(TEXTURE2D_PARAM(normalMap, samplerNormalMap), float2 uv, float3 normalWS, float3 tangentWS, float3 bitangentWS)
            {
                float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(normalMap, samplerNormalMap, uv));
                float3x3 tangentToWorld = float3x3(tangentWS, bitangentWS, normalWS);
                return normalize(mul(normalTS, tangentToWorld));
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                // 获取控制贴图
                float4 splatControl = SAMPLE_TEXTURE2D(_SplatMap, sampler_SplatMap, input.uv);
                
                // 确保权重和为1
                float weightSum = splatControl.r + splatControl.g + splatControl.b + splatControl.a;
                splatControl /= weightSum;
                
                // 采样各层纹理
                float2 uvSplat0 = input.uv * _Tiling.x;
                float2 uvSplat1 = input.uv * _Tiling.y;
                float2 uvSplat2 = input.uv * _Tiling.z;
                float2 uvSplat3 = input.uv * _Tiling.w;
                
                float4 splat0 = SAMPLE_TEXTURE2D(_Splat0, sampler_Splat0, uvSplat0);
                float4 splat1 = SAMPLE_TEXTURE2D(_Splat1, sampler_Splat1, uvSplat1);
                float4 splat2 = SAMPLE_TEXTURE2D(_Splat2, sampler_Splat2, uvSplat2);
                float4 splat3 = SAMPLE_TEXTURE2D(_Splat3, sampler_Splat3, uvSplat3);
                
                // 混合颜色
                float4 albedo = splat0 * splatControl.r + 
                               splat1 * splatControl.g + 
                               splat2 * splatControl.b + 
                               splat3 * splatControl.a;
                
                // 混合法线贴图
                float3 normal0 = GetNormalFromMap(TEXTURE2D_ARGS(_Normal0, sampler_Normal0), uvSplat0, input.normalWS, input.tangentWS, input.bitangentWS);
                float3 normal1 = GetNormalFromMap(TEXTURE2D_ARGS(_Normal1, sampler_Normal1), uvSplat1, input.normalWS, input.tangentWS, input.bitangentWS);
                float3 normal2 = GetNormalFromMap(TEXTURE2D_ARGS(_Normal2, sampler_Normal2), uvSplat2, input.normalWS, input.tangentWS, input.bitangentWS);
                float3 normal3 = GetNormalFromMap(TEXTURE2D_ARGS(_Normal3, sampler_Normal3), uvSplat3, input.normalWS, input.tangentWS, input.bitangentWS);
                
                float3 normal = normalize(normal0 * splatControl.r + 
                                         normal1 * splatControl.g + 
                                         normal2 * splatControl.b + 
                                         normal3 * splatControl.a);
                
                // 为弱表面法线使用几何法线
                normal = lerp(input.normalWS, normal, 0.8);
                normal = normalize(normal);
                
                // 获取主光源
                Light mainLight = GetMainLight(input.shadowCoord);
                
                float3 viewDir = normalize(input.viewDirWS);
                
                // 计算光照强度 (卡通风格)
                float NdotL = dot(normal, mainLight.direction);
                float toonRampThreshold = _ToonRamp;
                float lightIntensity = smoothstep(toonRampThreshold - _SmoothAmount, toonRampThreshold + _SmoothAmount, NdotL * mainLight.shadowAttenuation);
                float4 light = lightIntensity * float4(mainLight.color, 1);
                
                // 计算高光
                float3 halfVector = normalize(mainLight.direction + viewDir);
                float NdotH = dot(normal, halfVector);
                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
                float4 specular = specularIntensitySmooth * _SpecularColor;
                
                // 计算边缘光
                float rimDot = 1 - dot(viewDir, normal);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                float4 rim = rimIntensity * _RimColor;
                
                // 获取基础纹理
                half4 baseTexture = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                
                // 最终混合所有效果
                return _Color * albedo * baseTexture * (_AmbientColor + light + specular + rim);
            }
            ENDHLSL
        }
        
        // 阴影处理Pass
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull Back

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        
        // 深度写入Pass
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
    
    // 备用渲染内容用于不支持URP的平台
    FallBack "Universal Render Pipeline/Lit"
}