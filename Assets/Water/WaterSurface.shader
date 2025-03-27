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
        
        // ��Ҫ����͸�����
        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            // ����Shadertoy�еĳ�������
            float _DragMult; // ������קǿ��
            float _WaterDepth; // ˮ��
            float _CameraHeight; // ����߶�
            float4 _WaterColor; // ˮ��ɫ
            float4 _MousePos; // ���λ�ã���Ҫ�ӽű�����
            
            #define ITERATIONS_RAYMARCH 12 // ���߲�����������
            #define ITERATIONS_NORMAL 36 // ���㷨��ʱ�ĵ�������
            
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
            
            // ���ز���ֵ���䵼��
            float2 wavedx(float2 position, float2 direction, float frequency, float timeshift)
            {
                float x = dot(direction, position) * frequency + timeshift;
                float wave = exp(sin(x) - 1.0);
                float dx = wave * cos(x);
                return float2(wave, -dx);
            }
            
            // ���㲨�˵���
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
                    // ���ɲ��˷���
                    float2 p = float2(sin(iter), cos(iter));
                    
                    // ���㲨������
                    float2 res = wavedx(position, p, frequency, _Time.y * timeMultiplier + wavePhaseShift);
                    
                    // ���ݲ�����ק�͵����ƶ�λ��
                    position += p * res.y * weight * _DragMult;
                    
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
            
            // �����н���ˮ��
            float raymarchwater(float3 camera, float3 start, float3 end, float depth)
            {
                float3 pos = start;
                float3 dir = normalize(end - start);
                
                for(int i=0; i < 64; i++)
                {
                    // �߶ȴ�0��-depth
                    float height = getwaves(pos.xz, ITERATIONS_RAYMARCH) * depth - depth;
                    
                    // ������˸߶ȼ��������߸߶�ƥ�䣬��������в��������о���
                    if(height + 0.01 > pos.y)
                    {
                        return distance(pos, camera);
                    }
                    
                    // ���ݸ߶Ȳ�ƥ����ǰ����
                    pos += dir * (pos.y - height);
                }
                
                // ���δ���У���������ж��㣬
                // ��ʹ�����н����죬�����ڸ�Զ�ľ��뿴��������
                return distance(start, camera);
            }
            
            // ͨ������㴦�ĸ߶Ⱥ͸���������ĸ߶������㷨��
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
            
            // ����Χ������תָ���Ƕȵ���ת����
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
            
            // �����������
            float3 getRay(float2 fragCoord, float2 screenSize, float2 mousePos)
            {
                float2 uv = ((fragCoord.xy / screenSize) * 2.0 - 1.0) * float2(screenSize.x / screenSize.y, 1.0);
                float3 proj = normalize(float3(uv.x, uv.y, 1.5));
                
                // �����Ļ���С��600����Ӧ�������ת
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
            
            // ����ƽ���ཻ���
            float intersectPlane(float3 origin, float3 direction, float3 planePoint, float3 normal)
            {
                return clamp(dot(planePoint - origin, normal) / dot(direction, normal), -1.0, 9991999.0);
            }
            
            // �ǳ����������ٵĴ�������
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
            
            // ����̫������
            float3 getSunDirection()
            {
                return normalize(float3(-0.0773502691896258, 0.5 + sin(_Time.y * 0.2 + 2.6) * 0.45, 0.5773502691896258));
            }
            
            // ��ȡ��������Ĵ�����ɫ
            float3 getAtmosphere(float3 dir)
            {
                return extra_cheap_atmosphere(dir, getSunDirection()) * 0.5;
            }
            
            // ��ȡ���������̫����ɫ
            float getSun(float3 dir)
            {
                return pow(max(0.0, dot(dir, getSunDirection())), 720.0) * 210.0;
            }
            
            // ɫ��ӳ�亯��
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
                // ��ȡ����ռ�λ��
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // ��ȡ�۲췽��
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                // ��UV������ȡ����
                float3 ray = getRay(i.uv * _ScreenParams.xy, _ScreenParams.xy, _MousePos.xy);
                
                if (ray.y >= 0.0)
                {
                    // ���ray.yΪ������Ⱦ���
                   // float3 C = getAtmosphere(ray) + getSun(ray);
                  //  return float4(aces_tonemap(C * 2.0), 1.0);
                  return 0;
                }
                
                // ����ray.y����Ϊ����ˮ����뱻����
                // ����ˮƽ��
                float3 waterPlaneHigh = float3(0.0, 0.0, 0.0);
                float3 waterPlaneLow = float3(0.0, -_WaterDepth, 0.0);
                
                // ��������ԭ��
                float3 origin = float3(_Time.y * 0.2, _CameraHeight, 1);
                
                // �����ཻ�㲢�ؽ�λ��
                float highPlaneHit = intersectPlane(origin, ray, waterPlaneHigh, float3(0.0, 1.0, 0.0));
                float lowPlaneHit = intersectPlane(origin, ray, waterPlaneLow, float3(0.0, 1.0, 0.0));
                float3 highHitPos = origin + ray * highPlaneHit;
                float3 lowHitPos = origin + ray * lowPlaneHit;
                
                // ��ˮ���й��߲������ؽ�����λ��
                float dist = raymarchwater(origin, highHitPos, lowHitPos, _WaterDepth);
                float3 waterHitPos = origin + ray * dist;
                
                // ��������λ�õķ���
                float3 N = normal(waterHitPos.xz, 0.01, _WaterDepth);
                
                // �����ƽ�������Ա����Ƶ��������
                N = lerp(N, float3(0.0, 1.0, 0.0), 0.8 * min(1.0, sqrt(dist * 0.01) * 1.1));
                
                // ���������ϵ��
                float fresnel = (0.04 + (1.0 - 0.04) * (pow(1.0 - max(0.0, dot(-N, ray)), 5.0)));
                
                // �������߲�ȷ����������Ծ
                float3 R = normalize(reflect(ray, N));
                R.y = abs(R.y);
                
                // ���㷴��ͽ��ƴα���ɢ��
                float3 reflection = getAtmosphere(R) + getSun(R);
                float3 scattering = _WaterColor.rgb * 0.1 * (0.2 + (waterHitPos.y + _WaterDepth) / _WaterDepth);
                
                // ������Ͻ��
                float3 C = fresnel * reflection + scattering;
                return float4(aces_tonemap(C * 2.0), 1.0);
            }
            ENDCG
        }
    }
}