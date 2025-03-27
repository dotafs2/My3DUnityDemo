Shader "Custom/OceanWater"
{
    Properties
    {
        _WaterDepth ("Water Depth", Range(0.1, 5.0)) = 1.0
        _DragMult ("Wave Drag Multiplier", Range(0.1, 1.0)) = 0.38
        _CameraHeight ("Camera Height", Range(0.5, 3.0)) = 1.5
        _WaterColor ("Water Color", Color) = (0.0293, 0.0698, 0.1717, 1.0)
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        
        // 需要开启透明混合
        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            // 代替Shadertoy中的常量定义
            float _DragMult; // 波浪拖拽强度
            float _WaterDepth; // 水深
            float _CameraHeight; // 相机高度
            float4 _WaterColor; // 水颜色
            float4 _MousePos; // 鼠标位置，需要从脚本传入
            
            #define ITERATIONS_RAYMARCH 12 // 光线步进迭代次数
            #define ITERATIONS_NORMAL 36 // 计算法线时的迭代次数
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };
            
            // 返回波浪值及其导数
            float2 wavedx(float2 position, float2 direction, float frequency, float timeshift)
            {
                float x = dot(direction, position) * frequency + timeshift;
                float wave = exp(sin(x) - 1.0);
                float dx = wave * cos(x);
                return float2(wave, -dx);
            }
            
            // 计算波浪叠加
            float getwaves(float2 position, int iterations)
            {
                float wavePhaseShift = length(position) * 0.1;
                float iter = 0.0;
                float frequency = 1.0;
                float timeMultiplier = 2.0;
                float weight = 1.0;
                float sumOfValues = 0.0;
                float sumOfWeights = 0.0;
                
                for(int i=0; i < iterations; i++)
                {
                    // 生成波浪方向
                    float2 p = float2(sin(iter), cos(iter));
                    
                    // 计算波浪数据
                    float2 res = wavedx(position, p, frequency, _Time.y * timeMultiplier + wavePhaseShift);
                    
                    // 根据波浪拖拽和导数移动位置
                    position += p * res.y * weight * _DragMult;
                    
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
            
            // 光线行进到水面
            float raymarchwater(float3 camera, float3 start, float3 end, float depth)
            {
                float3 pos = start;
                float3 dir = normalize(end - start);
                
                for(int i=0; i < 64; i++)
                {
                    // 高度从0到-depth
                    float height = getwaves(pos.xz, ITERATIONS_RAYMARCH) * depth - depth;
                    
                    // 如果波浪高度几乎与射线高度匹配，则假设命中并返回命中距离
                    if(height + 0.01 > pos.y)
                    {
                        return distance(pos, camera);
                    }
                    
                    // 根据高度不匹配向前迭代
                    pos += dir * (pos.y - height);
                }
                
                // 如果未命中，则假设命中顶层，
                // 这使光线行进更快，并且在更远的距离看起来更好
                return distance(start, camera);
            }
            
            // 通过计算点处的高度和附近两个点的高度来计算法线
            float3 normal(float2 pos, float e, float depth)
            {
                float2 ex = float2(e, 0);
                float H = getwaves(pos.xy, ITERATIONS_NORMAL) * depth;
                float3 a = float3(pos.x, H, pos.y);
                return normalize(
                    cross(
                        a - float3(pos.x - e, getwaves(pos.xy - ex.xy, ITERATIONS_NORMAL) * depth, pos.y),
                        a - float3(pos.x, getwaves(pos.xy + ex.yx, ITERATIONS_NORMAL) * depth, pos.y + e)
                    )
                );
            }
            
            // 生成围绕轴旋转指定角度的旋转矩阵
            float3x3 createRotationMatrixAxisAngle(float3 axis, float angle)
            {
                float s = sin(angle);
                float c = cos(angle);
                float oc = 1.0 - c;
                return float3x3(
                    oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
                    oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
                    oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c
                );
            }
            
            // 生成相机射线
            float3 getRay(float2 fragCoord, float2 screenSize, float2 mousePos)
            {
                float2 uv = ((fragCoord.xy / screenSize) * 2.0 - 1.0) * float2(screenSize.x / screenSize.y, 1.0);
                float3 proj = normalize(float3(uv.x, uv.y, 1.5));
                
                // 如果屏幕宽度小于600，不应用鼠标旋转
                if (screenSize.x < 600.0)
                {
                    return proj;
                }
                
                float2 normalizedMouse = mousePos / screenSize;
                return mul(
                    createRotationMatrixAxisAngle(float3(0.0, -1.0, 0.0), 3.0 * ((normalizedMouse.x + 0.5) * 2.0 - 1.0)),
                    mul(
                        createRotationMatrixAxisAngle(float3(1.0, 0.0, 0.0), 0.5 + 1.5 * (((normalizedMouse.y == 0.0 ? 0.27 : normalizedMouse.y) * 1.0) * 2.0 - 1.0)),
                        proj
                    )
                );
            }
            
            // 射线平面相交检查
            float intersectPlane(float3 origin, float3 direction, float3 planePoint, float3 normal)
            {
                return clamp(dot(planePoint - origin, normal) / dot(direction, normal), -1.0, 9991999.0);
            }
            
            // 非常基础但快速的大气近似
            float3 extra_cheap_atmosphere(float3 raydir, float3 sundir)
            {
                float special_trick = 1.0 / (raydir.y * 1.0 + 0.1);
                float special_trick2 = 1.0 / (sundir.y * 11.0 + 1.0);
                float raysundt = pow(abs(dot(sundir, raydir)), 2.0);
                float sundt = pow(max(0.0, dot(sundir, raydir)), 8.0);
                float mymie = sundt * special_trick * 0.2;
                float3 suncolor = lerp(float3(1.0, 1.0, 1.0), max(float3(0.0, 0.0, 0.0), float3(1.0, 1.0, 1.0) - float3(5.5, 13.0, 22.4) / 22.4), special_trick2);
                float3 bluesky = float3(5.5, 13.0, 22.4) / 22.4 * suncolor;
                float3 bluesky2 = max(float3(0.0, 0.0, 0.0), bluesky - float3(5.5, 13.0, 22.4) * 0.002 * (special_trick + -6.0 * sundir.y * sundir.y));
                bluesky2 *= special_trick * (0.24 + raysundt * 0.24);
                return bluesky2 * (1.0 + 1.0 * pow(1.0 - raydir.y, 3.0));
            }
            
            // 计算太阳方向
            float3 getSunDirection()
            {
                return normalize(float3(-0.0773502691896258, 0.5 + sin(_Time.y * 0.2 + 2.6) * 0.45, 0.5773502691896258));
            }
            
            // 获取给定方向的大气颜色
            float3 getAtmosphere(float3 dir)
            {
                return extra_cheap_atmosphere(dir, getSunDirection()) * 0.5;
            }
            
            // 获取给定方向的太阳颜色
            float getSun(float3 dir)
            {
                return pow(max(0.0, dot(dir, getSunDirection())), 720.0) * 210.0;
            }
            
            // 色调映射函数
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
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                // 获取世界空间位置
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // 获取观察方向
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                // 从UV和鼠标获取射线
                float3 ray = getRay(i.uv * _ScreenParams.xy, _ScreenParams.xy, _MousePos.xy);
                
                if (ray.y >= 0.0)
                {
                    // 如果ray.y为正，渲染天空
                   // float3 C = getAtmosphere(ray) + getSun(ray);
                  //  return float4(aces_tonemap(C * 2.0), 1.0);
                  return 0;
                }
                
                // 现在ray.y必须为负，水面必须被击中
                // 定义水平面
                float3 waterPlaneHigh = float3(0.0, 0.0, 0.0);
                float3 waterPlaneLow = float3(0.0, -_WaterDepth, 0.0);
                
                // 定义射线原点
                float3 origin = float3(_Time.y * 0.2, _CameraHeight, 1);
                
                // 计算相交点并重建位置
                float highPlaneHit = intersectPlane(origin, ray, waterPlaneHigh, float3(0.0, 1.0, 0.0));
                float lowPlaneHit = intersectPlane(origin, ray, waterPlaneLow, float3(0.0, 1.0, 0.0));
                float3 highHitPos = origin + ray * highPlaneHit;
                float3 lowHitPos = origin + ray * lowPlaneHit;
                
                // 对水进行光线步进并重建命中位置
                float dist = raymarchwater(origin, highHitPos, lowHitPos, _WaterDepth);
                float3 waterHitPos = origin + ray * dist;
                
                // 计算命中位置的法线
                float3 N = normal(waterHitPos.xz, 0.01, _WaterDepth);
                
                // 随距离平滑法线以避免高频噪声干扰
                N = lerp(N, float3(0.0, 1.0, 0.0), 0.8 * min(1.0, sqrt(dist * 0.01) * 1.1));
                
                // 计算菲涅尔系数
                float fresnel = (0.04 + (1.0 - 0.04) * (pow(1.0 - max(0.0, dot(-N, ray)), 5.0)));
                
                // 反射射线并确保它向上跳跃
                float3 R = normalize(reflect(ray, N));
                R.y = abs(R.y);
                
                // 计算反射和近似次表面散射
                float3 reflection = getAtmosphere(R) + getSun(R);
                float3 scattering = _WaterColor.rgb * 0.1 * (0.2 + (waterHitPos.y + _WaterDepth) / _WaterDepth);
                
                // 返回组合结果
                float3 C = fresnel * reflection + scattering;
                return float4(aces_tonemap(C * 2.0), 1.0);
            }
            ENDCG
        }
    }
}