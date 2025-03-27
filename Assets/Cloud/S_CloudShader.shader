Shader "Custom/VolumetricClouds"
{
    Properties
    {
        _Noise2Da ("Noise 2D A", 2D) = "white" {}
        _Noise2Db ("Noise 2D B", 2D) = "white" {}
        _Noise3Da ("Noise 3D A", 3D) = "" {}
        _Noise3Db ("Noise 3D B", 3D) = "" {}
         _Noise3DaTile("Noise 3D A Tile", Vector) = (1,1,1,1)
        // �Լ����� tiling, speed, boundMin/Max, etc...
    }

    SubShader
    {
        Pass
        {
            // ������ HLSL ��
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // ��� URP ��Ҫ include ��

            // =====================================
            // ����һ��Ҫ�� C# ��������ȫ�ֱ���
            // =====================================
            float4 _BoundMin;
            float4 _BoundMax;

            float4 _Noise2DaTile; // x,y: tile; z,w: ����������ǿ��/scale
            float4 _Noise2DaSpeed;

            // ... ��������Ҫ�� uniform / sampler
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
            // SampleNoiseDensity ����
            // =====================================
            float SampleNoiseDensity(float3 worldPos, float time)
            {
                float noise = 0.0;

                // ��ʾ�ԣ�������һ���߶����ߣ������Ʒֲ�
                float heightT = saturate((worldPos.y - _BoundMin.y) / (_BoundMax.y - _BoundMin.y));

                // ���������������
                float2 uv2D = worldPos.xz * _Noise2DaTile.xy;
                float noise2D = SAMPLE_TEXTURE2D(_Noise2Da, sampler_Noise2Da, uv2D);

                // �򵥼��㣨ʾ����
                noise += noise2D * 0.5 * heightT;

                // 3D ����
                float3 uv3D = worldPos * _Noise3DaTile.xyz;
                float noise3D = SAMPLE_TEXTURE3D(_Noise3Da, sampler_Noise3Da, uv3D);

                noise += noise3D * 0.5 * heightT;

                // ����Ҫ������ֵ�ü������߻��֮��
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

            // ������ɫ��
            VS_OUT vert(VS_IN v)
            {
                VS_OUT o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.worldPos = TransformObjectToWorld(v.positionOS.xyz);
                return o;
            }

            // ƬԪ��ɫ��
            float4 frag(VS_OUT i) : SV_Target0
            {
                // ������ʾֻ��� worldPos.xyz �����ܶ� w
                // �����Ҳ������� render target��MRT���� SV_Target1��SV_Target2 ��
                float time = _Time.y;
                float cloudDensity = SampleNoiseDensity(i.worldPos, time);

                return float4(i.worldPos.xyz, cloudDensity);
            }

            ENDHLSL
        }
    }
    FallBack "Hidden/AlwaysIncludedShader"
}
