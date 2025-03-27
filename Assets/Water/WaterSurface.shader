Shader "Custom/OceanWaterVertex"
{
    Properties
    {
        _WaterDepth ("Water Depth", Range(0.1, 5.0)) = 1.0
        _DragMult ("Wave Drag Multiplier", Range(0.1, 1.0)) = 0.38
        _WaterColor ("Water Color", Color) = (0.0293, 0.0698, 0.1717, 1.0)
        _SunDirection ("Sun Direction", Vector) = (-0.0773502691896258, 0.5, 0.5773502691896258, 0)
        _SunIntensity ("Sun Intensity", Range(1.0, 500.0)) = 210.0
        _SunColor ("Sun Color", Color) = (1.0, 1.0, 0.9, 1.0)
        _FresnelPower ("Fresnel Power", Range(1.0, 10.0)) = 5.0
        _WaveHeight ("Wave Height", Range(0.0, 2.0)) = 0.5
        _WaveScale ("Wave Scale", Range(0.1, 10.0)) = 1.0
        _WaveSpeed ("Wave Speed", Range(0.1, 5.0)) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        
        // ����͸�����
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            // ���Զ���
            float _WaterDepth;
            float _DragMult;
            float4 _WaterColor;
            float4 _SunDirection;
            float _SunIntensity;
            float4 _SunColor;
            float _FresnelPower;
            float _WaveHeight;
            float _WaveScale;
            float _WaveSpeed;
            
            #define ITERATIONS_NORMAL 6
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float4 projPos : TEXCOORD4;
                float3 worldTangent : TEXCOORD5;
                float3 worldBinormal : TEXCOORD6;
            };
            
            // ���˺��� - ���ɻ����Ĳ��˸߶Ⱥ͵���
            float2 wavedx(float2 position, float2 direction, float frequency, float timeshift)
            {
                float x = dot(direction, position) * frequency + timeshift;
                float wave = exp(sin(x) - 1.0);
                float dx = wave * cos(x);
                return float2(wave, -dx);
            }
            
            // �����㲨�˵���
            float getwaves(float2 position, int iterations, float timeMultiplier)
            {
                float iter = 0.0;
                float frequency = _WaveScale;
                float weight = 1.0;
                float sumOfValues = 0.0;
                float sumOfWeights = 0.0;
                float2 p = position;
                
                for(int i=0; i < iterations; i++)
                {
                    // ���ɲ��˷���
                    float2 dir = float2(sin(iter), cos(iter));
                    
                    // ���㲨�˸߶�
                    float2 res = wavedx(p, dir, frequency, _Time.y * _WaveSpeed * timeMultiplier);
                    
                    // ���ݲ�����ק�͵����ƶ�λ��
                    p += dir * res.y * weight * _DragMult;
                    
                    // ��ӽ�����ܺ�
                    sumOfValues += res.x * weight;
                    sumOfWeights += weight;
                    
                    // �޸���һ���˶�����
                    weight = lerp(weight, 0.0, 0.2);
                    frequency *= 1.18;
                    timeMultiplier *= 1.07;
                    
                    // ������ֵʹ��һ��������Ҳ�������
                    iter += 1232.399963;
                }
                
                return sumOfValues / sumOfWeights;
            }
            
            // ���㷨�ߺ���
            float3 calculateNormal(float2 pos, float e, float time)
            {
                float2 ex = float2(e, 0);
                float h1 = getwaves(pos, ITERATIONS_NORMAL, time);
                float h2 = getwaves(pos - ex.xy, ITERATIONS_NORMAL, time);
                float h3 = getwaves(pos + ex.yx, ITERATIONS_NORMAL, time);
                
                float3 a = float3(pos.x, h1, pos.y);
                float3 b = float3(pos.x - e, h2, pos.y);
                float3 c = float3(pos.x, h3, pos.y + e);
                
                return normalize(cross(a - b, a - c));
            }
            
            // ������ɫ��
            v2f vert(appdata v)
            {
                v2f o;
                
                // ��ȡ������ģ�Ϳռ��λ��
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                // ���㲨�˸߶�
                float2 worldXZ = worldPos.xz;
                float wave = getwaves(worldXZ * 0.1, 8, 2.0);
                
                // Ӧ�ò��˸߶ȵ�����Y����
                worldPos.y += wave * _WaveHeight;
                
                // �����µ�����ռ�λ��
                float3 worldPosition = worldPos.xyz;
                
                // ���㲨�˷���
                float3 waveNormal = calculateNormal(worldXZ * 0.1, 0.01, 2.0);
                
                // ���㶥������߿ռ�
                float3 worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);
                float3 worldTangent = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                
                // ����TBN����
                float3x3 tbn = float3x3(worldTangent, worldBinormal, worldNormal);
                
                // �����˷��ߴ����߿ռ�ת��Ϊ����ռ�
                // ע�⣺ԭʼƽ��ķ���Ӧ�������ϵ�(0,1,0)����������ʹ�ü򵥵��滻����
                worldNormal = waveNormal; // ֱ��ʹ�ü���Ĳ��˷���
                
                // ���ն���λ��
                o.vertex = UnityWorldToClipPos(worldPosition);
                o.worldPos = worldPosition;
                o.worldNormal = worldNormal;
                o.worldTangent = worldTangent;
                o.worldBinormal = worldBinormal;
                o.uv = v.uv;
                o.viewDir = normalize(UnityWorldSpaceViewDir(worldPosition));
                o.projPos = ComputeScreenPos(o.vertex);
                
                return o;
            }
            
            // ����ɢ�����
            float3 calculateAtmosphere(float3 rayDir, float3 sunDir)
            {
                float special_trick = 1.0 / (rayDir.y * 1.0 + 0.1);
                float special_trick2 = 1.0 / (sunDir.y * 11.0 + 1.0);
                float raysundt = pow(abs(dot(sunDir, rayDir)), 2.0);
                float sundt = pow(max(0.0, dot(sunDir, rayDir)), 8.0);
                float mymie = sundt * special_trick * 0.2;
                float3 suncolor = lerp(float3(1.0, 1.0, 1.0), max(float3(0.0, 0.0, 0.0), float3(1.0, 1.0, 1.0) - float3(5.5, 13.0, 22.4) / 22.4), special_trick2);
                float3 bluesky = float3(5.5, 13.0, 22.4) / 22.4 * suncolor;
                float3 bluesky2 = max(float3(0.0, 0.0, 0.0), bluesky - float3(5.5, 13.0, 22.4) * 0.002 * (special_trick + -6.0 * sunDir.y * sunDir.y));
                bluesky2 *= special_trick * (0.24 + raysundt * 0.24);
                return bluesky2 * (1.0 + 1.0 * pow(1.0 - rayDir.y, 3.0));
            }
            
            // ��ȡ̫���߹�
            float getSunHighlight(float3 rayDir, float3 sunDir)
            {
                return pow(max(0.0, dot(rayDir, sunDir)), 720.0) * _SunIntensity;
            }
            
            // ACESɫ��ӳ��
            float3 aces_tonemap(float3 color)
            {
                float3x3 m1 = float3x3(
                    0.59719, 0.07600, 0.02840,
                    0.35458, 0.90834, 0.13383,
                    0.04823, 0.01566, 0.83777
                );
                float3x3 m2 = float3x3(
                    1.60475, -0.10208, -0.00327,
                    -0.53108, 1.10813, -0.07276,
                    -0.07367, -0.00605, 1.07602
                );
                float3 v = mul(m1, color);
                float3 a = v * (v + 0.0245786) - 0.000090537;
                float3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
                return pow(clamp(mul(m2, (a / b)), 0.0, 1.0), float3(1.0 / 2.2, 1.0 / 2.2, 1.0 / 2.2));
            }
            
            // Ƭ����ɫ��
            fixed4 frag(v2f i) : SV_Target
            {
                // ��һ������
                float3 viewDir = normalize(i.viewDir);
                float3 worldNormal = normalize(i.worldNormal);
                float3 sunDir = normalize(_SunDirection.xyz);
                
                // ���������ϵ��
                float fresnel = (0.04 + (1.0 - 0.04) * pow(1.0 - max(0.0, dot(worldNormal, viewDir)), _FresnelPower));
                
                // ��������
                float3 reflectVector = reflect(-viewDir, worldNormal);
                reflectVector.y = abs(reflectVector.y); // ȷ����������
                
                // ���㷴����ɫ
                float3 reflectionColor = calculateAtmosphere(reflectVector, sunDir);
                float sunHighlight = getSunHighlight(reflectVector, sunDir);
                reflectionColor += sunHighlight * _SunColor.rgb;
                
                // ����ˮ��ɢ����ɫ
                float depth = 1.0 - (i.worldPos.y / _WaterDepth + 1.0);
                depth = saturate(depth); // ȷ��ֵ��0-1��Χ��
                float3 scatteringColor = _WaterColor.rgb * 0.1 * (0.2 + depth);
                
                // �ϲ���ɫ
                float3 finalColor = lerp(scatteringColor, reflectionColor, fresnel);
                
                // Ӧ��ɫ��ӳ��
                finalColor = aces_tonemap(finalColor * 2.0);
                
                return float4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}