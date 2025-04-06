Shader "Cloud/CloudMarching"
{
    //=========================
    // 1) 属性(Properties)
    //=========================
    // 这些参数可在 Unity Inspector 或 Material 面板中设置，
    // 用于控制云噪声、云密度、步进、光照迭代等。
    Properties
    {
        // --- 蓝噪纹理，用于分层采样减少噪点(也可做抖动) ---
        _BlueNoise ("BlueNoise", 2D) = "black" {}
        _BlueNoiseScale ("BlueNoiseScale", Range(0, 6)) = 1

        // --- 高度曲线纹理，用于在不同高度控制云的形状 ---
        [NoScaleOffset] _HeightCurveA ("HeightCurveA", 2D) = "white" {}
        [NoScaleOffset] _HeightCurveB ("HeightCurveB", 2D) = "white" {}

        // --- 二维噪声A，用于云的细节或动态变化 ---
        [NoScaleOffset] _Noise2Da ("Noise2Da", 2D) = "white" {}
        _Noise2DaTile ("Noise2DaTile", Vector) = (1, 1, 1, 1)       // xy=平铺系数, z=unused, w=平铺倍数
        _Noise2DaSpeed ("Noise2DaSpeed", Vector) = (0, 0, 0, 0)    // 噪声在 XY 上移动速度

        // --- 二维噪声B，用于与 HeightCurve 混合控制云高度 ---
        [NoScaleOffset] _Noise2Db ("Noise2Db", 2D) = "white" {}
        _Noise2DbTile ("Noise2DbTile", Vector) = (1, 1, 1, 1)

        // --- 三维噪声A，用于云体积细节 ---
        [NoScaleOffset] _Noise3Da ("Noise3Da", 3D) = "white" {}
        _Noise3DaTile ("Noise3DaTile", Vector) = (1, 1, 1, 1)       
        _Noise3DaSpeed ("Noise3DaSpeed", Vector) = (0, 0, 0, 0)    // 三维噪声在 XYZ 上移动速度

        // --- 三维噪声B, 与前者叠加形成更复杂体积噪声 ---
        [NoScaleOffset] _Noise3Db ("Noise3Db", 3D) = "white" {}
        _Noise3DbTile ("Noise3DbTile", Vector) = (1, 1, 1, 1)

        // --- 噪声裁剪阈值，小于此值的噪声将被视作无云 ---
        _NoiseCullThreshold ("NoiseCullThreshold", Range(0, 1)) = 0

        // --- 云体(密度)相关 ---
        _DensityScale ("DensityScale", Range(0, 6)) = 1            // 全局云密度放大倍数
        _DensityStepLength ("DensityStepLength", Range(0, 3)) = 0.25 // Raymarch 的步进距离
        _DensityIteration ("DensityIteration", Range(1, 256)) = 8  // Raymarch 最大步数

        // --- 光照相关 ---
        _LightScale ("LightScale", Range(0, 6)) = 1                // 光衰减或散射的强度
        _LightStepLength ("LightStepLength", Range(0, 3)) = 0.25   // 二级Raymarch(光线采样)的步长
        _LightIteration ("LightIteration", Range(1, 64)) = 8       // 二级Raymarch(光线采样)的迭代次数
        [NoScaleOffset] _LightAttenuationCurve ("LightAttenuationCurve", 2D) = "white" {}

        // --- 云位置插值(估算位置) ---
        _CloudEstimatePosLerp ("CloudEstimatePosLerp", Range(0, 1)) = 0
    }

    SubShader
    {
        Pass
        {
            //=========================
            // 2) Pass 设置
            //=========================
            // 这里指定该 Pass 属于透明队列、URP Forward 渲染，
            // 并且关闭深度写入(ZWrite Off)，让云半透明叠加。
            Tags { "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" "LightMode"="UniversalForward" }
           // ZWrite Off
           ZWrite Off         // 不写入深度


           //  Cull Off
            HLSLPROGRAM
            // 指定顶点着色器 vs: vert, 片元着色器 ps: frag
            #pragma vertex vert
            #pragma fragment frag
            
            // 包含了 URP 的一些核心函数和 Lighting 计算
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            // 引入我们的 RayBoxDistance.hlsl，用于射线和包围盒相交计算
            #include "Assets/Cloud/RayBoxDistance.hlsl"


            //=========================
            // 3) 数据结构定义
            //=========================
            struct VertexInput
            {
                float4 vertex : POSITION; // 模型空间顶点位置
            };

            struct VertexOutput
            {
                float4 vertex   : SV_POSITION; // 裁剪空间坐标(供 GPU raster 使用)
                float3 worldPos : TEXCOORD0;   // 世界坐标，用于后续片元计算
                float4 screenPos: TEXCOORD1;   // 临时存储裁剪空间位置，便于计算屏幕UV
            };

            struct FragmentOutput
            {
                float4 color0 : SV_Target0; // 输出到 MRT 第0通道(云位置+密度)
                float4 color1 : SV_Target1; // 输出到 MRT 第1通道(云运动向量+光照强度)
            };


            //=========================
            // 4) Uniform / 纹理采样器
            //=========================
            sampler2D _BlueNoise;
            float4 _BlueNoise_ST;     // 蓝噪纹理 UV 变换
            float  _BlueNoiseScale;   // 蓝噪采样强度

            // 用于云高度形状控制的纹理
            sampler2D _HeightCurveA;
            sampler2D _HeightCurveB;

            // 二维噪声 A & B
            sampler2D _Noise2Da;
            float4 _Noise2DaTile;
            float4 _Noise2DaSpeed;

            sampler2D _Noise2Db;
            float4 _Noise2DbTile;

            // 三维噪声 A & B
            sampler3D _Noise3Da;
            float4 _Noise3DaTile;
            float4 _Noise3DaSpeed;

            sampler3D _Noise3Db;
            float4 _Noise3DbTile;

            // 噪声阈值，用于裁剪低密度云
            float _NoiseCullThreshold;

            // Raymarch 主要控制
            float _DensityScale;
            float _DensityStepLength;
            int   _DensityIteration;

            // 光照采样控制
            float _LightScale;
            float _LightStepLength;
            int   _LightIteration;
            sampler2D _LightAttenuationCurve; // 光衰减曲线(纹理)

            // 云位置估计(插值)
            float _CloudEstimatePosLerp;

            // 光照方向 & 云包围盒
            float3 _LightDir;
            float3 _BoundMin;
            float3 _BoundMax;

            //=========================
            // 5) 工具函数
            //=========================

            // 用于判断某点是否出界(超出云包围盒)
            bool IsOutOfBound(float3 worldPos) {
                if(worldPos.x > _BoundMax.x || worldPos.x < _BoundMin.x)
                    return true;
                if(worldPos.y > _BoundMax.y || worldPos.y < _BoundMin.y)
                    return true;
                if(worldPos.z > _BoundMax.z || worldPos.z < _BoundMin.z)
                    return true;
                return false;
            }


            // 采样噪声密度(核心函数)，叠加多种纹理噪声并做阈值处理
            float SampleNoiseDensity(float3 worldPos) {
                float noise = 0;

                // 1) 根据世界坐标 y，映射到 [0,1] 用于采样高度曲线
                float4 heightCurveUV = 0;
                heightCurveUV.x = (worldPos.y - _BoundMin.y) / (_BoundMax.y - _BoundMin.y);

                // 从两张高度曲线纹理获取值
                float heightCurveA = tex2Dlod(_HeightCurveA, heightCurveUV);
                float heightCurveB = tex2Dlod(_HeightCurveB, heightCurveUV);

                // 2) 二维噪声 B，用来在 [heightCurveA, heightCurveB] 之间混合
                float4 noise2DbUV = float4(worldPos.xz, 0, 0);
                noise2DbUV.xy *= _Noise2DbTile.xy * _Noise2DbTile.w;
                float noise2Db = tex2Dlod(_Noise2Db, noise2DbUV);

                float heightCurve = lerp(heightCurveA, heightCurveB, noise2Db);
                // 如果在这个高度曲线下为0，则直接无云
                if(heightCurve == 0) {
                    return 0;
                }

                // 3) 二维噪声 A：可随时间移动，用于增加动态云效果
                float4 noise2DaUV = float4(worldPos.xz, 0, 0);
                noise2DaUV.xy += _Noise2DaSpeed.xy * _Time.y;            // 噪声UV随时间偏移
                noise2DaUV.xy *= _Noise2DaTile.xy * _Noise2DaTile.w;
                noise += tex2Dlod(_Noise2Da, noise2DaUV) * 0.55;

                // 4) 三维噪声 A：也可随时间移动
                float4 noise3DaUV = float4(worldPos, 0);
                noise3DaUV.xyz += _Noise3DaSpeed.xyz * _Time.y;          // 同理，时间偏移
                noise3DaUV.xyz *= _Noise3DaTile.xyz * _Noise3DaTile.w;
                noise += tex3Dlod(_Noise3Da, noise3DaUV) * 0.25;

                // 5) 三维噪声 B：再叠加一次
                float4 noise3DbUV = float4(worldPos * _Noise3DbTile.xyz * _Noise3DbTile.w, 0);
                noise += tex3Dlod(_Noise3Db, noise3DbUV) * 0.2;

                // 6) 叠加噪声乘以高度曲线
                noise *= heightCurve;

                // 7) 裁剪阈值
                if(noise < _NoiseCullThreshold) {
                    noise = 0;
                }

                return noise;
            }

            //=========================
            // 6) 顶点着色器(vert)
            //=========================
            VertexOutput vert (VertexInput v)
            {
                VertexOutput o;

                // 将模型空间的顶点转换到 裁剪空间
                o.vertex = TransformObjectToHClip(v.vertex.xyz);

                // 保留世界坐标，后续片元 Shader 会基于此做 Raymarch
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);

                // 同时保存一份裁剪空间坐标到 screenPos，用于片元阶段计算屏幕UV
                o.screenPos = o.vertex;
                #if UNITY_UV_STARTS_AT_TOP
                o.screenPos.y *= -1;
                #endif

                return o;
            }

            //=========================
            // 7) 片元着色器(frag)
            //=========================
            FragmentOutput frag (VertexOutput i)
            {
                //----------- 7.1 还原屏幕UV，用于蓝噪等需要屏幕空间的采样 -----------
                i.screenPos.xyz /= i.screenPos.w;
                float2 screenUV = i.screenPos.xy;
                screenUV = (screenUV + 1) / 2;

                //----------- 7.2 采样蓝噪纹理，用于抖动或随机采样 -----------
                float2 blueNoiseUV = (screenUV + _Time.yy * 11.1) * _BlueNoise_ST.xy;
                float blueNoise = tex2D(_BlueNoise, blueNoiseUV);

                //----------- 7.3 准备射线起点、方向 -----------
                float3 rayStart = i.worldPos;
                // rayDir：从相机位置 指向 顶点(worldPos)的方向
                // 这里 normalize(...) 保证方向是单位向量
                float3 rayDir = normalize(i.worldPos - _WorldSpaceCameraPos.xyz);

                //----------- 7.4 与云包围盒求交 -----------
                float3 inPos;
                float3 outPos;


                // 使用 RayBoxDistance 计算射线与包围盒的交点
                // rayDir * 1000 => 让射线足够长
                float hit = RayBoxDistance(_BoundMin, _BoundMax, rayStart, rayDir * 1000, inPos, outPos);
                                                                   


                //----------- 7.5 准备云体/光照累积变量 -----------
                float cloudDensity = 0;               // 云密度累计
                float lightIntensity = 0;             // 光衰减累计
                float volumetricLightIntensity = 0;   // (暂时没用到)
                float3 cloudStartPos = -999999;       // 记录云体出现的起点(世界坐标)
                float3 cloudEndPos   = -999999;       // 记录云体出现的终点(世界坐标)

                // 算出射线经过盒子的最大距离
                float maxDensityLength = distance(inPos, outPos);



                //----------- 7.6 主Raymarch循环(采样云密度) -----------
                for(int iii = 0; iii < _DensityIteration; iii++) {
                    // 距离 = (步序号 + 随机抖动) × 步长
                    float densityLength = (iii + blueNoise * _BlueNoiseScale) * _DensityStepLength;
                    if(densityLength > maxDensityLength) {
                        // 超过盒子长度就退出
                        break;
                    }
                    
                    // 当前采样位置：inPos + 射线方向 × 采样距离
                    float3 densityStepPos = inPos + rayDir * densityLength;
                    
                    // 如果超出包围盒(安全检查)
                    if(IsOutOfBound(densityStepPos)){
                        break;
                    }

                    // 采样云密度
                    float stepCloudDensity = SampleNoiseDensity(densityStepPos) * _DensityScale;
                    if(stepCloudDensity == 0){
                        // 如果此处密度=0，则继续下一个步
                        continue;
                    }

                    // 如果这是第一次采样到云(云密度从0变到>0)，记录云起点
                    if(cloudDensity == 0) {
                        cloudStartPos = densityStepPos;
                    }

                    // 更新云的终点 & 累加云密度
                    cloudEndPos = densityStepPos;
                    cloudDensity = saturate(cloudDensity + stepCloudDensity);
                    
                    //----------- 7.7 在同一采样点，再沿光方向做二级Raymarch(光照衰减) -----------
                    float depth = 0;
                    for(int jjj = 0; jjj < _LightIteration; jjj++) {
                        if(lightIntensity >= 1)
                            break;

                        float lightLength = (jjj + blueNoise * _BlueNoiseScale) * _LightStepLength;
                        
                        // 沿着光方向，从当前采样点往外探测
                        float3 lightMarchPos = densityStepPos + _LightDir * lightLength;
                        if(IsOutOfBound(lightMarchPos)) 
                            break;

                        depth += SampleNoiseDensity(lightMarchPos);
                    }

                    // 平均光衰减强度
                    depth /= _LightIteration;

                    // 根据深度(遮挡)用衰减曲线查表
                    float lightInAttenuation  = tex2Dlod(_LightAttenuationCurve, float4(depth, 0, 0, 0)); 
                    float lightOutAttenuation = tex2Dlod(_LightAttenuationCurve, float4(cloudDensity, 0, 0, 0)); 
                    lightOutAttenuation = pow(lightOutAttenuation, 2);

                    // 累加光衰减(根据采样)
                    lightIntensity += lightInAttenuation * lightOutAttenuation * _LightScale;
                    lightIntensity = saturate(lightIntensity);

                    // 如果云密度累加到 >= 1，就可以终止(表示云非常厚)
                    if(cloudDensity >= 1)
                        break;
                }
                //----------- 7.8 云位置估算(简单的起点终点插值) -----------
                // 在渲染或其它需要时，可以把云的代表位置估算出来
                float3 cloudEstimatePos = lerp(cloudStartPos, cloudEndPos, _CloudEstimatePosLerp);

                // 计算云的运动向量(基于噪声速度等)
                float3 cloudEstimateMotionVector = (_Noise3DaSpeed + float3(_Noise2DaSpeed.x, 0, _Noise2DaSpeed.y)) * _Time.y;

                //----------- 7.9 将结果写进 FragmentOutput (MRT) -----------
                FragmentOutput output = (FragmentOutput)0;
                
                // For debugging: Make clouds red when camera is inside the bounding box
                // color0: (xyz=云的世界坐标, w=云密度)
                 output.color0 = float4(cloudEstimatePos, cloudDensity);

                // color1: (xyz=云的运动向量, w=光强度)
                output.color1 = float4(cloudEstimateMotionVector, lightIntensity);

                return output;
            }
            ENDHLSL
        }
    }
}
