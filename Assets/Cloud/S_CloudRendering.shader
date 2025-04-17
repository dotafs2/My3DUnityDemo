Shader "Cloud/CloudRendering"
{
    // 1. 属性区 (Properties) 
    Properties
    {
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        _LightPower ("LightPower", Float) = 1
        _RimColor0 ("RimColor0", Color) = (1, 1, 1, 1)
        _RimPower0 ("RimPower0", Float) = 4
        _DarkColor ("DarkColor", Color) = (0, 0, 0, 1)
        _DarkPower ("DarkPower", Float) = 4
        _ForwardScatteringPower ("ForwardScatteringPower", Float) = 1
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                "Queue"="Transparent"             // 透明队列
                "RenderPipeline"="UniversalPipeline"
                "LightMode"="UniversalForward"    // 在URP的Forward管线下执行
            }

            ZWrite Off       // 在本 Pass 里禁止写入深度缓冲
           // ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"

            // ------------- struct 定义 -------------
            struct VertexInput
            {
                float4 vertex : POSITION;
            };

            struct VertexOutput
            {
                float4 vertex : SV_POSITION;   // 最终顶点位置（裁剪空间）
                float4 screenPos : TEXCOORD1;  // 用于片元着色器中还原屏幕坐标
            };

            // ------------- 属性同名的变量声明 -------------
            float4 _BaseColor;

            float _LightPower;

            float4 _RimColor0;
            float _RimPower0;

            float4 _DarkColor;
            float _DarkPower;

            float _ForwardScatteringPower;

            // 来自上层脚本或其他地方传进来的光照信息
            float3 _LightDir;      // 方向光方向
            float4 _LightColor;    // 方向光颜色

            // 当前帧渲染出的Raymarch中间RT
            //   - _CurrentCameraTarget0: xyz存云点位置，a存云密度
            //   - _CurrentCameraTarget1: xyz可能存别的信息(比如光的方向或遮挡等), a存光的强度
            sampler2D _CurrentCameraTarget0;
            sampler2D _CurrentCameraTarget1;


            // ------------- 顶点着色器 -------------
            VertexOutput vert (VertexInput v)
            {
                VertexOutput o;

                // 1) 将模型空间下的顶点转换到 裁剪空间
                o.vertex = TransformObjectToHClip(v.vertex.xyz);

                // 2) 为片元着色器准备一个 screenPos，供后续计算纹理坐标
                o.screenPos = o.vertex;

                // 兼容 Mac / OpenGL 纹理坐标可能Y翻转
                #if UNITY_UV_STARTS_AT_TOP
                o.screenPos.y *= -1;
                #endif

                return o;
            }

            // ------------- 片元着色器 -------------
            float4 frag (VertexOutput i) : SV_Target
            {
                // ★ 1) 还原屏幕UV
                // i.screenPos.xyz /= i.screenPos.w => (clip空间 -> NDC空间)
                // screenUV在 [-1,1] 范围, 再映射到 [0,1]
                i.screenPos.xyz /= i.screenPos.w;
                float2 screenUV = i.screenPos.xy;
                screenUV = (screenUV + 1) / 2;

                // ★ 2) 采样之前Raymarch或云渲染过程输出的两个RT
                float4 renderRT0 = tex2D(_CurrentCameraTarget0, screenUV); // xyz=云世界坐标,a=云密度
                float4 renderRT1 = tex2D(_CurrentCameraTarget1, screenUV); // 可能xyz=.., a=光强度

                float cloudDensity = renderRT0.a;     // 云密度
                float3 cloudPos    = renderRT0.xyz;   // 云像素所在的世界坐标
                float lightIntensity = renderRT1.a;   // 光的强度(方向光)

                // 给光强做个指数放大
                lightIntensity = pow(lightIntensity, _LightPower);

                // ★ 3) 计算外围(边缘)的高光(Rim)颜色
                //    rimColor0 = (RimColor) × (光强^RimPower) × 2
                float4 rimColor0 = _RimColor0 * pow(lightIntensity, _RimPower0) * 2;

                // ★ 4) 计算暗部调制(DarkColor)
                //    逻辑: 当光强度小，则(1 - lightIntensity) 越大,
                //          pow(1 - lightIntensity, _DarkPower) 也越大，渐渐从白过渡到 _DarkColor
                float4 darkColor = lerp(
                    /* from: */ 1,
                    /* to:   */ _DarkColor,
                    /* alpha: */ pow(1 - lightIntensity, _DarkPower)
                );

                // ★ 5) 计算视线方向 & 前向散射(Forward Scattering)
                //    假设: cloudPos - cameraPos => 从相机到云的位置向量
                //    dot(viewDir, _LightDir) => 与光线同向程度 => 前向散射
                float3 viewDir = normalize(cloudPos - _WorldSpaceCameraPos.xyz);
                float forwardScattering = saturate(dot(viewDir, _LightDir));
                forwardScattering = pow(forwardScattering, _ForwardScatteringPower);

                // ★ 6) 累乘/叠加各种颜色因素
                float4 color = _BaseColor;                // 先从 _BaseColor 开始
                color.rgb *= lerp(0, 1, lightIntensity);  // 用光强来衰减或放大BaseColor
                color.rgb += rimColor0.rgb;               // 加上边缘高光
                color.rgb *= darkColor;                   // 与暗部调制混合(类似阴影或暗角效果)
                color.rgb += _LightColor.rgb * forwardScattering; // 叠加前向散射的光

                // ★ 7) 最终 alpha = 云的密度(决定了最后屏幕合成的透明度)
                color.a = cloudDensity;
                return color;
            }
            ENDHLSL
        }
    }
}