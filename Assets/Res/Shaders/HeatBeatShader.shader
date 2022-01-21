Shader "QING/HeartBeatShader2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BackTex ("Texture", 2D) = "white" {}
        _Radius ("Radius", Range(1, 2000)) = 2
        _Transparent ("Transparent", Range(0,1)) = 0.5
        _Color  ("Color", Color) = (1,1,1,1)
        _FallOff ("FallOf", Range(0, 5)) = 0.1
    }
    SubShader
    {
        Tags { 
            "Queue" = "Transparent"
			"RenderType" = "Transparent"
			"IgnoreProjector" = "True"
        }
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
            float _FallOff;

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

            // 将rgb转色彩饱和度  色调（H），饱和度（S），明度（V）。
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
                /* 
                0.0125786164 | 0.0251572327 | 0.0314465409 | 0.0251572327 | 0.0125786164
                0.0251572327 | 0.0566037736 | 0.0754716981 | 0.0566037736 | 0.0251572327
                0.0314465409 | 0.0754716981 | 0.0943396226 | 0.0754716981 | 0.0314465409
                0.0251572327 | 0.0566037736 | 0.0754716981 | 0.0566037736 | 0.0251572327
                0.0125786164 | 0.0251572327 | 0.0314465409 | 0.0251572327 | 0.0125786164
                */
                float2 texelSize = _MainTex_TexelSize;
                fixed4 color = fixed4(0,0,0,0);

				color += tex2D(_MainTex, uv + float2(-texelSize.x*2, -texelSize.y*2)) * 0.0125786164;
                color += tex2D(_MainTex, uv + float2(-texelSize.x*2,   -texelSize.y)) * 0.0251572327;
				color += tex2D(_MainTex, uv + float2(-texelSize.x*2,              0)) * 0.0314465409;
				color += tex2D(_MainTex, uv + float2(-texelSize.x*2,    texelSize.y)) * 0.0251572327;
                color += tex2D(_MainTex, uv + float2(-texelSize.x*2,  texelSize.y*2)) * 0.0125786164;

                color += tex2D(_MainTex, uv + float2(  -texelSize.x, -texelSize.y*2)) * 0.0251572327;
                color += tex2D(_MainTex, uv + float2(  -texelSize.x,   -texelSize.y)) * 0.0566037736;
				color += tex2D(_MainTex, uv + float2(  -texelSize.x,              0)) * 0.0754716981;
				color += tex2D(_MainTex, uv + float2(  -texelSize.x,    texelSize.y)) * 0.0566037736;
                color += tex2D(_MainTex, uv + float2(  -texelSize.x,  texelSize.y*2)) * 0.0251572327;

                color += tex2D(_MainTex, uv + float2(             0, -texelSize.y*2)) * 0.0314465409;
                color += tex2D(_MainTex, uv + float2(             0,   -texelSize.y)) * 0.0754716981;
				color += tex2D(_MainTex, uv + float2(             0,              0)) * 0.0943396226;
				color += tex2D(_MainTex, uv + float2(             0,    texelSize.y)) * 0.0754716981;
                color += tex2D(_MainTex, uv + float2(             0,  texelSize.y*2)) * 0.0314465409;

                color += tex2D(_MainTex, uv + float2(   texelSize.x, -texelSize.y*2)) * 0.0251572327;
                color += tex2D(_MainTex, uv + float2(   texelSize.x,   -texelSize.y)) * 0.0566037736;
				color += tex2D(_MainTex, uv + float2(   texelSize.x,              0)) * 0.0754716981;
				color += tex2D(_MainTex, uv + float2(   texelSize.x,    texelSize.y)) * 0.0566037736;
                color += tex2D(_MainTex, uv + float2(   texelSize.x,  texelSize.y*2)) * 0.0251572327;

                color += tex2D(_MainTex, uv + float2( texelSize.x*2, -texelSize.y*2)) * 0.0125786164;
                color += tex2D(_MainTex, uv + float2( texelSize.x*2,   -texelSize.y)) * 0.0251572327;
				color += tex2D(_MainTex, uv + float2( texelSize.x*2,              0)) * 0.0314465409;
				color += tex2D(_MainTex, uv + float2( texelSize.x*2,    texelSize.y)) * 0.0251572327;
                color += tex2D(_MainTex, uv + float2( texelSize.x*2,  texelSize.y*2)) * 0.0125786164;

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
            // 计算亮度
            fixed luminance(fixed4 color) 
            {
			    return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
    		}
            // 提取图片的亮度  _LuminanceThreshold 为亮度值 低于为0
            fixed4 TexLuminance(v2f i)
            {
                half _LuminanceThreshold = 0.1;
                fixed4 c = tex2D(_MainTex, i.uv);
			    fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);

			    return c * val;
            }

            /* 圆角矩形的核心代码 */
            float udRoundBox(float2 p, float2 b, float r)
            {
                return length(max(abs(p) - b  + r,0.0)) - r; 
            }

            #define COLOR_NUM 5
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 abledo = tex2D(_MainTex, i.uv).rgb;
                // 1. 原图高斯模糊
                fixed4 gus = gaussian_blur_3v3(i.uv);
                // 2. 去掉饱和度
                fixed3 hsb = rgb2hsv(gus); //  色调（H），饱和度（S），明度（V）。
                hsb.g = 0;
                fixed3 rgb = hsv2rgb(hsb);
                // 3. 反转
                fixed invert_ = gus.g * 0.59 + gus.r * 0.3 + gus.b * 0.11;
                fixed r = 1 - invert_;
                fixed g = 1 - invert_;
                fixed b = 1 - invert_;

                // fixed Rate = 1.004;
                // fixed r = ( 1 - rgb.r * Rate) / Rate;
                // fixed g = ( 1 - rgb.g * Rate) / Rate;
                // fixed b = ( 1 - rgb.b * Rate) / Rate;

                fixed3 details = fixed3(r,g,b);
                // 4. 线性光 + 不透明度为65%
                fixed3 c = details * _Transparent + 2 * abledo - 1;

                fixed4 col = fixed4(c, 1.0);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
