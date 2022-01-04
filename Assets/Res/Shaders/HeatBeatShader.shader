Shader "QING/HeartBeatShader2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BackTex ("Texture", 2D) = "white" {}
        _Radius ("Radius", Range(1, 2000)) = 2
        _Transparent ("Transparent", Range(0,1)) = 0.5
        _Color  ("Color", Color) = (1,1,1,1)
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float2 _MainTex_TexelSize;
            float _Transparent;
            sampler2D _BackTex;
            float _Radius;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            #define PI 3.14159265359
            #define PI2 6.283185307

            // 将rgb转色彩饱和度
            float3 rgb2hsv(float3 c)
            {
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = c.g < c.b ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
                float4 q = c.r < p.x ? float4(p.xyw, c.r) : float4(c.r, p.yzx);

                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }
            // 色彩饱和度转rgb
            float3 hsv2rgb(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }

            fixed4 gaussian_blur_3v3(fixed2 uv)
            {
                /*
                   0.0947416 | 0.118318 | 0.0947416
                   0.118318  | 0.147761 | 0.118318
                   0.0947416 | 0.118318 | 0.0947416
                */
                float2 texelSize = _MainTex_TexelSize;
                fixed4 color = fixed4(0,0,0,0);

				color += tex2D(_MainTex, uv + float2(-texelSize.x, -texelSize.y)) * 0.0947416;
				color += tex2D(_MainTex, uv + float2(-texelSize.x,            0)) * 0.118318;
				color += tex2D(_MainTex, uv + float2(-texelSize.x,  texelSize.y)) * 0.0947416;

                color += tex2D(_MainTex, uv + float2(           0, -texelSize.y)) * 0.118318;
				color += tex2D(_MainTex, uv + float2(           0,            0)) * 0.147761;
				color += tex2D(_MainTex, uv + float2(           0,  texelSize.y)) * 0.118318;

                color += tex2D(_MainTex, uv + float2( texelSize.x, -texelSize.y)) * 0.0947416;
				color += tex2D(_MainTex, uv + float2( texelSize.x,            0)) * 0.118318;
				color += tex2D(_MainTex, uv + float2( texelSize.x,  texelSize.y)) * 0.0947416;

                return color;
            }

            fixed4 gaussian_blur_5v5(fixed2 uv)
            {
                /* 错误的卷积核
                0.0162162162 | 0.0540540541 | 0.1216216216 | 0.0540540541 | 0.0162162162
                0.0540540541 | 0.1216216216 | 0.1945945946 | 0.1216216216 | 0.0540540541
                0.1216216216 | 0.1945945946 | 0.2270270270 | 0.1945945946 | 0.1216216216
                0.0540540541 | 0.1216216216 | 0.1945945946 | 0.1216216216 | 0.0540540541
                0.0162162162 | 0.0540540541 | 0.1216216216 | 0.0540540541 | 0.0162162162
                */
                float2 texelSize = _MainTex_TexelSize;
                fixed4 color = fixed4(0,0,0,0);

				color += tex2D(_MainTex, uv + float2(-texelSize.x*2, -texelSize.y*2)) * 0.0162162162;
                color += tex2D(_MainTex, uv + float2(-texelSize.x*2,   -texelSize.y)) * 0.0540540541;
				color += tex2D(_MainTex, uv + float2(-texelSize.x*2,              0)) * 0.1216216216;
				color += tex2D(_MainTex, uv + float2(-texelSize.x*2,    texelSize.y)) * 0.0540540541;
                color += tex2D(_MainTex, uv + float2(-texelSize.x*2,  texelSize.y*2)) * 0.0162162162;

                color += tex2D(_MainTex, uv + float2(  -texelSize.x, -texelSize.y*2)) * 0.0540540541;
                color += tex2D(_MainTex, uv + float2(  -texelSize.x,   -texelSize.y)) * 0.1216216216;
				color += tex2D(_MainTex, uv + float2(  -texelSize.x,              0)) * 0.1945945946;
				color += tex2D(_MainTex, uv + float2(  -texelSize.x,    texelSize.y)) * 0.1216216216;
                color += tex2D(_MainTex, uv + float2(  -texelSize.x,  texelSize.y*2)) * 0.0540540541;

                color += tex2D(_MainTex, uv + float2(             0, -texelSize.y*2)) * 0.1216216216;
                color += tex2D(_MainTex, uv + float2(             0,   -texelSize.y)) * 0.1945945946;
				color += tex2D(_MainTex, uv + float2(             0,              0)) * 0.2270270270;
				color += tex2D(_MainTex, uv + float2(             0,    texelSize.y)) * 0.1945945946;
                color += tex2D(_MainTex, uv + float2(             0,  texelSize.y*2)) * 0.1216216216;

                color += tex2D(_MainTex, uv + float2(   texelSize.x, -texelSize.y*2)) * 0.0540540541;
                color += tex2D(_MainTex, uv + float2(   texelSize.x,   -texelSize.y)) * 0.1216216216;
				color += tex2D(_MainTex, uv + float2(   texelSize.x,              0)) * 0.1945945946;
				color += tex2D(_MainTex, uv + float2(   texelSize.x,    texelSize.y)) * 0.1216216216;
                color += tex2D(_MainTex, uv + float2(   texelSize.x,  texelSize.y*2)) * 0.0540540541;

                color += tex2D(_MainTex, uv + float2( texelSize.x*2, -texelSize.y*2)) * 0.0162162162;
                color += tex2D(_MainTex, uv + float2( texelSize.x*2,   -texelSize.y)) * 0.0540540541;
				color += tex2D(_MainTex, uv + float2( texelSize.x*2,              0)) * 0.1216216216;
				color += tex2D(_MainTex, uv + float2( texelSize.x*2,    texelSize.y)) * 0.0540540541;
                color += tex2D(_MainTex, uv + float2( texelSize.x*2,  texelSize.y*2)) * 0.0162162162;

                return normalize(color);
            }

            fixed4 laplace_sharp(fixed2 uv)
            {
                /*
                -1 -1 -1
                -1 8 -1
                -1 -1 -1
                */
                float2 texelSize = _MainTex_TexelSize;
                fixed4 color = fixed4(0,0,0,0);
                color += tex2D(_MainTex, uv + float2(-texelSize.x, -texelSize.y)) * -1;
				color += tex2D(_MainTex, uv + float2(-texelSize.x,            0)) * -1;
				color += tex2D(_MainTex, uv + float2(-texelSize.x,  texelSize.y)) * -1;

                color += tex2D(_MainTex, uv + float2(           0, -texelSize.y)) * -1;
				color += tex2D(_MainTex, uv + float2(           0,            0)) * 8;
				color += tex2D(_MainTex, uv + float2(           0,  texelSize.y)) * -1;

                color += tex2D(_MainTex, uv + float2( texelSize.x, -texelSize.y)) * -1;
				color += tex2D(_MainTex, uv + float2( texelSize.x,            0)) * -1;
				color += tex2D(_MainTex, uv + float2( texelSize.x,  texelSize.y)) * -1;

                return color;

            }

            float rand(fixed2 co)
            {
                return frac(sin(dot(co.xy, fixed2(12.9898,78.233)))*43758.5453);
                //return abs( frac( sin(co.x * 95325.328 + co.y * -48674.077) + cos(co.x * -46738.322 + co.y * 76485.077)) -.5)+.5;
            }

            #define COLOR_SAVE_NUM 5
            fixed4 frag (v2f i) : SV_Target
            {
                float2 texelSize = _MainTex_TexelSize;
                // 偏移uv
                fixed2 offset = fixed2(0.5, 0.5);
                fixed2 d = fixed2(i.uv.x - offset.x, i.uv.y - offset.y);
                // 所有uv到d点的距离
                //fixed br = min(0.8,length(_Radius * d));
                //fixed2 uv = i.uv;
                fixed4 color =  tex2D(_BackTex, i.uv) * 255.0;
                int4 temp = color / _Radius;
                fixed4 col = (temp * _Radius + _Radius*0.5)/255.0;// tex2D(_BackTex, uv) / br;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
