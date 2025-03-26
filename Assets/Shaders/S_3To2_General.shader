Shader "Custom/PBRNPRExample_URP"
{
    Properties
    {
        // 漫反射贴图
        _BaseMap("Base Map (Diffuse)", 2D) = "white" {}
        // SDF 面部贴图(R 通道阴影线, B 通道鼻子高光线等)
        _FaceMap("Face SDF Map", 2D) = "white" {}
        // 头发高光贴图 / 角色其它部位贴图等
        _SpecMap("Spec Map (Hair/Other)", 2D) = "white" {}
        // Ramp 贴图
        _RampDiffuse("Ramp Diffuse", 2D) = "white" {}

        // ---- 下列参数均可在 Inspector 调整 ----
        // ACES 逆向映射强度
        _ReverseACESIntensity("Reverse ACES Intensity", Range(0,1)) = 0.5

        // Toon 基础阴影相关
        _DiffuseSmoothStep("Diffuse SmoothStep", Range(0.0,1.0)) = 0.2
        _DiffuseBias("Diffuse Bias", Range(-1.0,1.0)) = 0.0

        // 光照颜色(亮部与暗部)
        _DayDiffuseColor("Day Diffuse Color", Color) = (1,1,1,1)
        _ShadowDiffuseColor("Shadow Diffuse Color", Color) = (0.5,0.5,0.5,1)

        // 次表面散射(SSS)模拟
        _SSSNdotVColor("SSS NdV Color", Color) = (1,0.8,0.8,1)
        _SSSNdotVColorIntensity("SSS NdV Intensity", Range(0,1)) = 0.3
        _SSSNdotVSmoothstep("SSS NdV Smoothstep", Range(0,1)) = 0.1
        _SSSNdotVBias("SSS NdV Bias", Range(-1,1)) = 0.0

        // 鼻子高光 SDF 阈值修正
        _noseHighLightStepValue("Nose highlight step offset", Range(-0.5, 0.5)) = 0.0

        // 高光相关
        _SpecColor("Specular Color", Color) = (1,1,1,1)
        _SpecRoughness("Spec Roughness", Range(0.01,1.0)) = 0.3
        _SpecPower("Spec Power", Range(0,2)) = 1.0

        // 头发高光强度等(如要用到)
        _SpecIntensity("Hair Spec Intensity", Range(0,3)) = 1.0

        // 眼睛示例：附加光强度
        _AddColorIntensity("Eye Additional Light Intensity", Range(0,2)) = 1.0
        _ColorIntensity("Eye BaseColor Intensity", Range(0,2)) = 1.0
    }

    SubShader
    {
        // 声明是 URP
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType" = "Opaque"
        }

        // 一个常见的前向通道 Pass
        Pass
        {
            Name "MainForward"
            Tags { "LightMode" = "UniversalForward" }

            // 如要配合模板测试眉毛、头发，请在此写 Stencil 块，或拆分多个 Pass
            Stencil
            {
                Ref 0
                ReadMask 255
                WriteMask 255
                Comp Always
                Pass Keep
            }

            HLSLPROGRAM
            // ------------------- 编译指令：-------------------
            #pragma vertex vert
            #pragma fragment frag

            // 与实例化兼容
            #pragma multi_compile_instancing

            // URP 关键字
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS

            // 需要的 HLSL 头文件
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadow.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            // ------------- 属性声明（与 Properties 对应）-------------
            sampler2D _BaseMap;
            float4 _BaseMap_ST;

            sampler2D _FaceMap;
            float4 _FaceMap_ST;

            sampler2D _SpecMap;
            float4 _SpecMap_ST;

            sampler2D _RampDiffuse;
            float4 _RampDiffuse_ST;

            float _ReverseACESIntensity;
            float _DiffuseSmoothStep;
            float _DiffuseBias;
            float4 _DayDiffuseColor;
            float4 _ShadowDiffuseColor;

            float4 _SSSNdotVColor;
            float _SSSNdotVColorIntensity;
            float _SSSNdotVSmoothstep;
            float _SSSNdotVBias;
            float _noseHighLightStepValue;

            float4 _SpecColor;
            float _SpecRoughness;
            float _SpecPower;
            float _SpecIntensity;

            float _AddColorIntensity;
            float _ColorIntensity;

            // ---------------- 结构声明 ----------------
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
                float2 uv1        : TEXCOORD1;   // 可能给头发高光或Face SDF等使用
                float4 tangentOS  : TANGENT;
                float4 color      : COLOR;       // 也可存顶点色
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : WORLD_POS;
                float3 normalWS    : NORMAL;
                float2 uv          : TEXCOORD0;
                float2 uv1         : TEXCOORD1;
                float4 color       : COLOR;

                // 用于主光源阴影计算
                float4 shadowCoord : TEXCOORD2;
            };

            // ---------------- 工具函数(文中提到的) ----------------

            // 逆 ACES 函数
            float3 reverseACES(float3 color)
            {
                // 3.4475*x^3 - 2.7866*x^2 + 1.2281*x - 0.0056
                return  3.4475 * color * color * color
                      - 2.7866 * color * color
                      + 1.2281 * color
                      - 0.0056;
            }

            // Schlick Fresnel
            float fresnelReflectance(float3 H, float3 V, float F0)
            {
                float base = 1.0 - dot(V, H);
                float exponent = pow(base, 5.0);
                return exponent + F0*(1.0 - exponent);
            }

            // Beckmann 分布
            float PHBeckmann(float ndoth, float m)
            {
                float alpha = acos(ndoth);
                float ta    = tan(alpha);
                float val   = 1.0/(m*m*pow(ndoth,4.0)) * exp(-(ta*ta)/(m*m));
                // 这里乘个 0.5 并 ^0.1 是文章中给的经验做法
                return 0.5 * pow(val, 0.1);
            }

            // ---------------- 顶点着色器 ----------------
            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                // 世界坐标
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                // 世界法线
                OUT.normalWS   = normalize(TransformObjectToWorldNormal(IN.normalOS));
                // 裁剪空间
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);

                // UV 赋值
                OUT.uv  = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.uv1 = IN.uv1;  // 可能给 FaceMap 或高光贴图使用
                OUT.color = IN.color;

                // 记录阴影坐标
                UNITY_TRANSFER_MAIN_LIGHT_SHADOW(OUT, OUT.positionWS);

                return OUT;
            }

            // ---------------- 像素着色器 ----------------
            float4 frag(Varyings IN) : SV_Target
            {
                // 标准化
                float3 normalWS = normalize(IN.normalWS);
                float3 viewDir  = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS);

                // 主光源
                Light mainLight = GetMainLight(IN.positionWS);
                float3 lightDir = normalize(mainLight.direction);

                // 主光源阴影
                float shadow = MAIN_LIGHT_SHADOW(IN.shadowCoord);

                // NdotL/NdotV
                float NdotL = saturate(dot(normalWS, lightDir));
                float NdotV = saturate(dot(normalWS, viewDir));

                // 采样基础贴图，做逆 ACES
                float3 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).rgb;
                float3 acesColor = reverseACES(baseColor);
                baseColor = lerp(baseColor, acesColor, _ReverseACESIntensity);

                //-------------------------------------------
                // 一、Toon 基础漫反射 + SmoothStep
                //-------------------------------------------
                // 这里加上 DiffuseBias 进行一点偏移
                float diffuseToon = smoothstep(
                    0.5 - _DiffuseSmoothStep, 
                    0.5 + _DiffuseSmoothStep,
                    max(NdotL*0.5 + 0.5 + _DiffuseBias*0.5, 0.0)
                );

                // 结合实时阴影
                diffuseToon *= shadow;

                //-------------------------------------------
                // 二、脸部 SDF 阴影线(示例)
                //-------------------------------------------
                float3 faceMap = SAMPLE_TEXTURE2D(_FaceMap, sampler_FaceMap, IN.uv1).rgb;
                // 假设 faceMap.r 对应脸部阴影线
                // faceMap.b 对应鼻子高光线
                // 需自己根据 UV1 / 法线投影来做一些点乘判断

                // 文章中有个: forwardWS = (0, -1, 0) 在 XZ 投影 与光方向 dot
                float2 forwardWS = normalize(TransformObjectToWorld(float3(0, -1, 0)).xz);
                float2 mainLightXZ = normalize(-mainLight.direction.xz);
                float WdotL = 1.0 - saturate(dot(forwardWS, mainLightXZ)*0.5 + 0.5);

                // faceMap.r 提前做下 pow
                faceMap.r = pow(faceMap.r, 0.55);

                // 计算 SDF-based “是否落入阴影线区域”
                float shadow1 = (WdotL < faceMap.r) ? 1.0 : 0.0; 
                // 鼻子区域 SDF
                float shadow3 = ((WdotL + _noseHighLightStepValue) < faceMap.b) ? 1.0 : 0.0;

                // 也可用 smoothstep(abs(WdotL - faceMap.r), ...) 做柔化

                //-------------------------------------------
                // 三、Ramp 采样 + 明暗色
                //-------------------------------------------
                float3 rampLookup = SAMPLE_TEXTURE2D(_RampDiffuse, sampler_\RampDiffuse, float2(diffuseToon, 0.1)).rgb;

                // 亮部(主光颜色 * baseColor)
                float3 dayDiffuse  = _DayDiffuseColor.rgb    * mainLight.color.rgb * diffuseToon * baseColor;
                // 暗部( ramp 颜色 * baseColor )
                float3 darkDiffuse = _ShadowDiffuseColor.rgb * rampLookup          * baseColor    * mainLight.color.rgb * (1.0 - diffuseToon);
                float3 rampResult  = dayDiffuse + darkDiffuse;

                //-------------------------------------------
                // 四、简单次表面散射模拟(SSS)
                //-------------------------------------------
                // 文章举例：NdotV + smoothstep
                float sssNdotV = smoothstep(
                    0.5 - _SSSNdotVSmoothstep, 
                    0.5 + _SSSNdotVSmoothstep*0.5,
                    (1.0 - saturate(NdotV - _SSSNdotVBias)) * (1.0 - saturate(NdotV))
                );

                // 最终 SSS 色 = (指定颜色 - 1) * 强度 * baseColor
                float3 sssColor = (_SSSNdotVColor.rgb - 1.0.xxx) 
                                  * _SSSNdotVColorIntensity 
                                  * sssNdotV 
                                  * baseColor;

                //-------------------------------------------
                // 五、自定义高光 (参考 Beckmann + Schlick)
                //-------------------------------------------
                float3 halfDir = normalize(lightDir + viewDir);
                float NdotH = saturate(dot(normalWS, halfDir));

                // Beckmann + Schlick
                float beckmannVal = PHBeckmann(NdotH, _SpecRoughness);
                // 这里文章中做了 2.0 * beckmannVal 再 pow(...,10.0) 之类的处理
                // 已在 PHBeckmann 里做一部分
                float F = fresnelReflectance(halfDir, viewDir, 0.028); // 0.028 ~ F0
                float frSpec = max(beckmannVal * F / dot(halfDir, halfDir), 0.0);

                // 最终高光强度
                float resultSpec = saturate(NdotL) * _SpecPower * frSpec;
                float3 specularColor = resultSpec * _SpecColor.rgb * shadow * baseColor * mainLight.color.rgb;

                //-------------------------------------------
                // 六、鼻子高光 / SDF 强调
                //-------------------------------------------
                // shadow3 表示落在 nose highlight SDF 区域
                // 可以让它直接叠加一些发亮
                float3 noseHL = shadow3 * baseColor * 1.2 * shadow * mainLight.color.rgb;

                // 将上面几个通道组合
                float3 finalColor = rampResult + sssColor + specularColor + noseHL;

                //-------------------------------------------
                // 七、多光源加成 (Additional Lights)
                //-------------------------------------------
                int pixelLightCount = GetAdditionalLightsCount();
                for(int i = 0; i < pixelLightCount; i++)
                {
                    Light addLight = GetAdditionalLight(i, IN.positionWS);
                    float3 addDir  = normalize(addLight.direction);

                    // Toon 额外光源
                    float NdotAddL = saturate(dot(normalWS, addDir));
                    float factor = smoothstep(
                        0.5 - _DiffuseSmoothStep - 0.3,
                        0.5 + _DiffuseSmoothStep + 0.3,
                        max(NdotAddL * 0.5 + 0.5, 0.0)
                    ) * addLight.distanceAttenuation;

                    // 叠加
                    finalColor += factor * addLight.color.rgb * baseColor;
                }

                // 一般写法：return float4(finalColor, 1);
                // 如果需要半透明等，可自行放到 alpha
                return float4(finalColor, 1.0);
            }

            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
}
