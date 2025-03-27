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
        
        // 启用透明混合
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            // 属性定义
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
            
            // 波浪函数 - 生成基本的波浪高度和导数
            float2 wavedx(float2 position, float2 direction, float frequency, float timeshift)
            {
                float x = dot(direction, position) * frequency + timeshift;
                float wave = exp(sin(x) - 1.0);
                float dx = wave * cos(x);
                return float2(wave, -dx);
            }
            
            // 计算多层波浪叠加
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
                    // 生成波浪方向
                    float2 dir = float2(sin(iter), cos(iter));
                    
                    // 计算波浪高度
                    float2 res = wavedx(p, dir, frequency, _Time.y * _WaveSpeed * timeMultiplier);
                    
                    // 根据波浪拖拽和导数移动位置
                    p += dir * res.y * weight * _DragMult;
                    
                    // 添加结果到总和
                    sumOfValues += res.x * weight;
                    sumOfWeights += weight;
                    
                    // 修改下一个八度音阶
                    weight = lerp(weight, 0.0, 0.2);
                    frequency *= 1.18;
                    timeMultiplier *= 1.07;
                    
                    // 添加随机值使下一波看起来也是随机的
                    iter += 1232.399963;
                }
                
                return sumOfValues / sumOfWeights;
            }
            
            // 计算法线函数
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
            
            // 顶点着色器
            v2f vert(appdata v)
            {
                v2f o;
                
                // 获取顶点在模型空间的位置
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                // 计算波浪高度
                float2 worldXZ = worldPos.xz;
                float wave = getwaves(worldXZ * 0.1, 8, 2.0);
                
                // 应用波浪高度到顶点Y坐标
                worldPos.y += wave * _WaveHeight;
                
                // 计算新的世界空间位置
                float3 worldPosition = worldPos.xyz;
                
                // 计算波浪法线
                float3 waveNormal = calculateNormal(worldXZ * 0.1, 0.01, 2.0);
                
                // 计算顶点的切线空间
                float3 worldNormal = mul((float3x3)unity_ObjectToWorld, v.normal);
                float3 worldTangent = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                
                // 构建TBN矩阵
                float3x3 tbn = float3x3(worldTangent, worldBinormal, worldNormal);
                
                // 将波浪法线从切线空间转换为世界空间
                // 注意：原始平面的法线应该是向上的(0,1,0)，所以我们使用简单的替换法线
                worldNormal = waveNormal; // 直接使用计算的波浪法线
                
                // 最终顶点位置
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
            
            // 大气散射近似
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
            
            // 获取太阳高光
            float getSunHighlight(float3 rayDir, float3 sunDir)
            {
                return pow(max(0.0, dot(rayDir, sunDir)), 720.0) * _SunIntensity;
            }
            
            // ACES色调映射
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
            
            // 片段着色器
            fixed4 frag(v2f i) : SV_Target
            {
                // 归一化向量
                float3 viewDir = normalize(i.viewDir);
                float3 worldNormal = normalize(i.worldNormal);
                float3 sunDir = normalize(_SunDirection.xyz);
                
                // 计算菲涅尔系数
                float fresnel = (0.04 + (1.0 - 0.04) * pow(1.0 - max(0.0, dot(worldNormal, viewDir)), _FresnelPower));
                
                // 反射向量
                float3 reflectVector = reflect(-viewDir, worldNormal);
                reflectVector.y = abs(reflectVector.y); // 确保反射向上
                
                // 计算反射颜色
                float3 reflectionColor = calculateAtmosphere(reflectVector, sunDir);
                float sunHighlight = getSunHighlight(reflectVector, sunDir);
                reflectionColor += sunHighlight * _SunColor.rgb;
                
                // 计算水体散射颜色
                float depth = 1.0 - (i.worldPos.y / _WaterDepth + 1.0);
                depth = saturate(depth); // 确保值在0-1范围内
                float3 scatteringColor = _WaterColor.rgb * 0.1 * (0.2 + depth);
                
                // 合并颜色
                float3 finalColor = lerp(scatteringColor, reflectionColor, fresnel);
                
                // 应用色调映射
                finalColor = aces_tonemap(finalColor * 2.0);
                
                return float4(finalColor, 1.0);
            }
            ENDCG
        }
    }
}