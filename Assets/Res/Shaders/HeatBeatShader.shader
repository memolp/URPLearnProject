Shader "QING/HeartBeatShader2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BackTex ("Texture", 2D) = "white" {}
        _Transparent ("Transparent", Range(0,1)) = 0.5
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

            #define COLOR_SAVE_NUM 2
            fixed4 frag (v2f i) : SV_Target
            {
                int radian_ = 2;
                int q_count[COLOR_SAVE_NUM];
                fixed3 q_count_col[COLOR_SAVE_NUM];
                for(int ii =0; ii < COLOR_SAVE_NUM; ii++)
                {
                    q_count[ii] = 0;
                    q_count_col[ii] = fixed3(0,0,0);
                }
                fixed3 out_col = fixed3(0,0,0);
                float2 texelSize = _MainTex_TexelSize;
                for(int dx =-radian_; dx <= radian_; dx++)
                {
                    for(int dy =-radian_; dy<=radian_; dy++)
                    {
                        fixed2 uv =  i.uv + fixed2(texelSize.x*dx, texelSize.y*dy);
                        fixed3 col = tex2D(_MainTex, uv).rgb;
                        fixed q = (col.r + col.g + col.b)/3;
                        int idx = q * COLOR_SAVE_NUM;
                        q_count[idx] += 1;
                        //fixed t = ;
                        q_count_col[idx] = col * idx * 1.0 / COLOR_SAVE_NUM;
                        //out_col += col;
                    }
                }
                int max_index = 0;
                int max_count = 0;
                for(int ii =0; ii <  COLOR_SAVE_NUM; ii++)
                {
                    if(q_count[ii] > max_count)
                    {
                        max_count = q_count[ii];
                        max_index = ii;
                    }
                }
                fixed3 c = q_count_col[max_index];
                fixed4 col = fixed4(c , 1);
                //fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
