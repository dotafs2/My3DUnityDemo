Shader "Custom/AnimatedColorTiles"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AudioTex ("Audio Texture", 2D) = "black" {}
        _TileScale ("Tile Scale", Float) = 5.0
        _AnimSpeed ("Animation Speed", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _AudioTex;
            float4 _MainTex_ST;
            float _TileScale;
            float _AnimSpeed;
            
            // HSV��RGBת������
            float3 hsv2rgb(float3 hsv)
            {
                hsv.yz = clamp(hsv.yz, 0.0, 1.0);
                return hsv.z * (1.0 + 0.5 * hsv.y * (cos(2.0 * UNITY_PI * (hsv.x + float3(0.0, 2.0 / 3.0, 1.0 / 3.0))) - 1.0));
            }

                       // ��������
            float fract(float x)
            {
                return x - floor(x);
            }
            
            // ��������ɺ���
            float rand(float2 seed)
            {
                return fract(sin(dot(seed, float2(12.9898, 78.233))) * 137.5453);
            }
            

            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // ��UV�������ŵ���Shadertoy���Ƶķ�Χ
                float2 frag = (2.0 * i.uv - 1.0) * _ScreenParams.y / _ScreenParams.x;
                
                // Ӧ�ñ���Ч�� - ʹ����Ƶ����
                float audioValue = tex2D(_AudioTex, float2(0.0, 0.0)).x;
                frag *= 1.0 - 0.2 * cos(frag.yx) * sin(UNITY_PI * 0.5 * audioValue);
                
                // Ӧ������
                frag *= _TileScale;
                
                // �������ֵ
                float random = rand(floor(frag));
                
                // ������ɫ����
                float2 black = smoothstep(1.0, 0.8, cos(frag * UNITY_PI * 2.0));
                
                // ����HSV��ɫ��ת��ΪRGB
                float3 color = hsv2rgb(float3(random, 1.0, 1.0));
                
                // ����Բ�β�Ӧ�ú�ɫ����
                color *= black.x * black.y * smoothstep(1.0, 0.0, length(fract(frag) - 0.5));
                
                // Ӧ�ö���
                float audioForAnim = tex2D(_AudioTex, float2(0.7, 0.0)).x;
                color *= 0.5 + 0.5 * cos(random + random * _Time.y * _AnimSpeed + _Time.y * _AnimSpeed + UNITY_PI * 0.5 * audioForAnim);
                
                return float4(color, 1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}