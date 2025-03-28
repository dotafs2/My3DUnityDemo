Shader "lcl/Water/Water_InteractionParticle2"
{
    Properties {
        [HDR]_ShallowColor("Shallow Color", Color) = (0.325, 0.807, 0.971, 0.725)
        [HDR]_DeepColor("Deep Color", Color) = (0.086, 0.407, 1, 0.749)

        _NormalTex ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Range(0, 10)) = 1.0
        _WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01
        _WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01
        _DepthMaxDistance("Depth Max Distance", Range(0,2)) = 1
        _FresnelPower ("Fresnel Power", Range(0, 10)) = 0
    }

    SubShader {
        Tags { "Queue"="Geometry" "RenderType"="Opaque" }

        // —— 无名 GrabPass，不指定自定义纹理名；Unity会自动把结果存在 _GrabTexture
        GrabPass {}

        Pass {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            // 1) 仅保留我们自己的贴图属性
            sampler2D _NormalTex;
            float4    _NormalTex_ST;
            float     _WaveXSpeed;
            float     _WaveYSpeed;
            float     _FresnelPower;
            float     _BumpScale;
            fixed4    _ShallowColor;
            fixed4    _DeepColor;
            half      _DepthMaxDistance;

            // 2) 使用内置的抓屏纹理 "_GrabTexture" 而不是 "_RefractionTex"
            sampler2D _GrabTexture;

            // 3) 若你使用内置深度贴图，需要
            sampler2D _CameraDepthTexture;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; 
                float4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;  
                float4 TtoW1 : TEXCOORD3;  
                float4 TtoW2 : TEXCOORD4; 
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // Unity 提供的宏，生成用于抓屏采样的屏幕坐标
                o.screenPos = ComputeGrabScreenPos(o.pos);

                o.uv.xy = TRANSFORM_TEX(v.texcoord, _NormalTex);

                float3 worldPos     = mul(unity_ObjectToWorld, v.vertex).xyz;  
                float3 worldNormal  = UnityObjectToWorldNormal(v.normal);  
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
                float3 worldBinormal= cross(worldNormal, worldTangent) * v.tangent.w; 

                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 1) 获取屏幕深度
                half existingDepth01   = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r;
                half existingDepthLinear= LinearEyeDepth(existingDepth01);
                half depthDifference   = existingDepthLinear - i.screenPos.w;
                half waterDepth01      = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor      = lerp(_ShallowColor, _DeepColor, waterDepth01);

                // 2) 计算动画法线
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                float3 viewDir  = normalize(UnityWorldSpaceViewDir(worldPos));
                float2 speed    = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);

                // 在法线贴图上取两个方向的扰动，再合并
                float3 bump1 = UnpackNormal(tex2D(_NormalTex, i.uv.xy + speed));
                float3 bump2 = UnpackNormal(tex2D(_NormalTex, i.uv.xy - speed));
                float3 bump  = normalize(bump1 + bump2);
                bump.xy      *= _BumpScale;

                // 3) 计算屏幕UV，并加上法线偏移
                float2 screenPos = i.screenPos.xy / i.screenPos.w;
                //   通常用 1.0 / _ScreenParams.xy 替代 TexelSize 手动声明
                float2 offset = bump.xy * (1.0 / _ScreenParams.xy) * i.screenPos.z;
                screenPos += offset;

                // 4) 采样抓屏图（折射色）
                float3 refrCol = tex2D(_GrabTexture, screenPos).rgb;

                // 5) 计算世界法线
                float3 normal = normalize(mul(float3x3(i.TtoW0.xyz, i.TtoW1.xyz, i.TtoW2.xyz), bump));

                // 6) 简单反射环境
                half  mip     = perceptualRoughnessToMipmapLevel(0);
                float3 reflDir= reflect(-viewDir, normal);
                half4 rgbm    = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, mip);
                float3 reflCol= DecodeHDR(rgbm, unity_SpecCube0_HDR);

                // 7) Fresnel 混合
                half fresnel     = pow(1 - saturate(dot(viewDir, normal)), _FresnelPower);
                float3 finalColor= reflCol * fresnel + refrCol * (1 - fresnel);

                return float4(finalColor, 1);
            }

            ENDCG
        }
    }
    FallBack Off
}
