Shader "Custom/VolumetricClouds"
{
    Properties
    {
        _Noise2Da ("Noise 2D A", 2D) = "white" {}
        _Noise2Db ("Noise 2D B", 2D) = "white" {}
        _Noise3Da ("Noise 3D A", 3D) = "" {}
        _Noise3Db ("Noise 3D B", 3D) = "" {}
         _Noise3DaTile("Noise 3D A Tile", Vector) = (1,1,1,1)
        // 以及各种 tiling, speed, boundMin/Max, etc...
    }

    SubShader
    {
        Pass
        {
            // 这里用 HLSL 块
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // 你的 URP 必要 include 等

            // =====================================
            // 声明一下要从 C# 传进来的全局变量
            // =====================================
            float4 _BoundMin;
            float4 _BoundMax;

            float4 _Noise2DaTile; // x,y: tile; z,w: 可能用来做强度/scale
            float4 _Noise2DaSpeed;

            // ... 其它你需要的 uniform / sampler
            TEXTURE2D(_Noise2Da);
            SAMPLER(sampler_Noise2Da);

            TEXTURE2D(_Noise2Db);
            SAMPLER(sampler_Noise2Db);

            TEXTURE3D(_Noise3Da);
            SAMPLER(sampler_Noise3Da);

            TEXTURE3D(_Noise3Db);
            SAMPLER(sampler_Noise3Db);


             float4 _Noise3DaTile;

            // =====================================
            // SampleNoiseDensity 函数
            // =====================================
            float SampleNoiseDensity(float3 worldPos, float time)
            {
                float noise = 0.0;

                // 演示性：例如做一个高度曲线，控制云分布
                float heightT = saturate((worldPos.y - _BoundMin.y) / (_BoundMax.y - _BoundMin.y));

                // 这里就做个最简计算
                float2 uv2D = worldPos.xz * _Noise2DaTile.xy;
                float noise2D = SAMPLE_TEXTURE2D(_Noise2Da, sampler_Noise2Da, uv2D);

                // 简单计算（示例）
                noise += noise2D * 0.5 * heightT;

                // 3D 噪声
                float3 uv3D = worldPos * _Noise3DaTile.xyz;
                float noise3D = SAMPLE_TEXTURE3D(_Noise3Da, sampler_Noise3Da, uv3D);

                noise += noise3D * 0.5 * heightT;

                // 视需要再做阈值裁剪、曲线混合之类
                // if(noise < threshold) noise = 0.0;

                return noise;
            }

            struct VS_IN
            {
                float4 positionOS : POSITION;
            };

            struct VS_OUT
            {
                float4 positionHCS : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            // 顶点着色器
            VS_OUT vert(VS_IN v)
            {
                VS_OUT o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.worldPos = TransformObjectToWorld(v.positionOS.xyz);
                return o;
            }

            // 片元着色器
            float4 frag(VS_OUT i) : SV_Target0
            {
                // 这里演示只输出 worldPos.xyz 和云密度 w
                // 你可以也输出到多 render target（MRT）的 SV_Target1、SV_Target2 等
                float time = _Time.y;
                float cloudDensity = SampleNoiseDensity(i.worldPos, time);

                return float4(i.worldPos.xyz, cloudDensity);
            }

            ENDHLSL
        }
    }
    FallBack "Hidden/AlwaysIncludedShader"
}
