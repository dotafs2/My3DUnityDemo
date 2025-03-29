Shader "Unlit/S_VolumetricCloud"
{
    Properties
    {
        _Noise2Da("Noise2Da", 2D) = "white" {}
        _Noise2Db("Noise2Db", 2D) = "white" {}
        _Noise3Da("Noise3Da", 3D) = "" {}
        _Noise3Db("Noise3Db", 3D) = "" {}
        _HeightCurveA("HeightCurveA", 2D) = "white" {}
        _HeightCurveB("HeightCurveB", 2D) = "white" {}
        _Noise2DaSpeed("Noise2DaSpeed", Vector) = (1,1,0,0)
        _Noise2DbSpeed("Noise2DbSpeed", Vector) = (1,1,0,0)
        _Noise2DaTile("Noise2DaTile", Vector) = (3, 2, 0, 0.5)
        _Noise2DbTile("Noise2DbTile", Vector) = (3, 2, 0, 0.5)

        _Noise2DaSpeed("Noise3DaSpeed", Vector) = (1,1,0,0)
        _Noise2DbSpeed("Noise3DbSpeed", Vector) = (1,1,0,0)
        _Noise2DaTile("Noise3DaTile", Vector) = (3, 2, 0, 0.5)
        _Noise2DbTile("Noise3DbTile", Vector) = (3, 2, 0, 0.5)



        _CameraPos("CameraPos", Vector) = (0,0,0,0)
        _BoundMin("BoundMin", Vector) = (0,0,0,0)
        _BoundMax("BoundMax", Vector) = (0,1,0,0)
        _NoiseCullThreshold("Cull", Float) = 0.2
        _Time("Time", Vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // 声明结构体和贴图
            sampler2D _Noise2Da, _Noise2Db, _HeightCurveA, _HeightCurveB;
            sampler3D _Noise3Da, _Noise3Db;

            float4 _Noise2DaTile,_Noise2DbTile,_Noise2DaSpeed,_Noise2DbSpeed;

            float4 _Noise3DaTile,_Noise3DbTile,_Noise3DaSpeed,_Noise3DbSpeed;

            float4 _CameraPos, _BoundMin, _BoundMax;
            float _NoiseCullThreshold;

            struct appdata { float4 vertex : POSITION; float2 uv : TEXCOORD0; };
            struct v2f { float2 uv : TEXCOORD0; float4 vertex : SV_POSITION; };

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float SampleNoiseDensity(float3 worldPos) {
                float noise = 0;
                // 控制不同云层的密度
                float4 heightCurveUV = 0;
                heightCurveUV.x = (worldPos.y - _BoundMin.y) / (_BoundMax.y - _BoundMin.y);
                float heightCurveA = tex2Dlod(_HeightCurveA, heightCurveUV);
                float heightCurveB = tex2Dlod(_HeightCurveB, heightCurveUV);

                float4 noise2DbUV = float4(worldPos.xz, 0, 0);
                noise2DbUV.xy *= _Noise2DbTile.xy * _Noise2DbTile.w;
                float noise2Db = tex2Dlod(_Noise2Db, noise2DbUV);
                
                float heightCurve = lerp(heightCurveA, heightCurveB, noise2Db);

                if(heightCurve == 0) {
                    return 0;
                }

                float4 noise2DaUV = float4(worldPos.xz, 0, 0);
                noise2DaUV.xy += _Noise2DaSpeed.xy * _Time.y;
                noise2DaUV.xy *= _Noise2DaTile.xy * _Noise2DaTile.w;
                noise += tex2Dlod(_Noise2Da, noise2DaUV) * 0.55;

                float4 noise3DaUV = float4(worldPos, 0);
                noise3DaUV.xyz += _Noise3DaSpeed.xyz * _Time.y;
                noise3DaUV.xyz *= _Noise3DaTile.xyz * _Noise3DaTile.w;
                noise += tex3Dlod(_Noise3Da, noise3DaUV) * 0.25;

                float4 noise3DbUV = float4(worldPos * _Noise3DbTile.xyz * _Noise3DbTile.w, 0);
                noise += tex3Dlod(_Noise3Db, noise3DbUV) * 0.2;

                noise *= heightCurve;

                if(noise < _NoiseCullThreshold) {
                    noise = 0;
                }

                return noise;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 rayOrigin = _CameraPos.xyz;
                float3 rayDir = float3(i.uv - 0.5, 1); // 简化模拟
                rayDir = normalize(rayDir);

                float density = 0;
                float3 pos = rayOrigin;

                // Raymarch 循环
                for (int step = 0; step < 64; step++) {
                    pos += rayDir * 0.1;
                    density += SampleNoiseDensity(pos);
                }

                return float4(density.xxx, 1);
            }
            ENDCG
        }
    }
}
