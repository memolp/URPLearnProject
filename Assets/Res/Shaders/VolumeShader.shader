Shader "QING/VolumeShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Center ("Center", vector) = (1,1,1,1)
        _Radius ("Radius", float) = 1
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        // Cull Off  ZTest Always
		// Blend SrcAlpha OneMinusSrcAlpha
// Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        Tags { "RenderType"="Opaque" }
        // Cull Off
        // ZWrite Off 
        // ZTest Always
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 wPos: TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Center;
            float4 _Color;
            float _Radius;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            bool sphereHit(half3 position)
            {
                return distance(position, _Center.xyz) < _Radius;
            }
            half sphereDistance(half3 position)
            {
                return distance(position, _Center.xyz);
            }

            half map(half3 p)
            {
                return distance(p, _Center) - _Radius;
            }

            half3 normal(half3 p)
            {
                const float eps = 0.01;
                half3 n = half3(0,0,0);
                half3 xdetal = half3(eps, 0, 0);
                half3 ydetal = half3(0, eps, 0);
                half3 zdetal = half3(0, 0, eps);
                n.x = map(p + xdetal) - map(p - xdetal);
                n.y = map(p + ydetal) - map(p - ydetal);
                n.z = map(p + zdetal) - map(p - zdetal);
                return normalize(n);
            }

            fixed4 simpleLambert(half3 normal)
            {
                half ndL = max(0, dot(normal, _WorldSpaceLightPos0));
                fixed4 c;
                c.rgb = _LightColor0  * ndL;
                c.a = 1;
                //return fixed4(1,0,0,1);
                return c;
            }


            fixed4 renderSurface(half3 p)
            {
                half3 n = normal(p);
                return simpleLambert(n);
            }

            
            fixed4 raymarch(half3 position, half3 direction)
            {
                for(int i =0; i < 50; i++)
                {
                    // sphereHit 方式
                    // if(sphereHit(position))
                    //     return fixed4(1,0,0,1);
                    // position += direction * 0.1;
                    // sphereDistance 方式
                    half dis = sphereDistance(position);
                    if(dis < _Radius)
                        return renderSurface(position);
                    position += direction * dis;
                }
                return _Color;
            }

            fixed3 spectral_jet(float w)
            {
                // w: [400, 700]
                // x: [0,   1]
                fixed x = saturate((w - 400.0)/300.0);
                fixed3 c;

                if (x < 0.25)
                    c = fixed3(0.0, 4.0 * x, 1.0);
                else if (x < 0.5)
                    c = fixed3(0.0, 1.0, 1.0 + 4.0 * (0.25 - x));
                else if (x < 0.75)
                    c = fixed3(4.0 * (x - 0.5), 1.0, 0.0);
                else
                    c = fixed3(1.0, 1.0 + 4.0 * (0.75 - x), 0.0);

                // Clamp colour components in [0,1]
                return saturate(c);
            }

            fixed3 spectral_bruton (float w)
            {
                fixed3 c;

                if (w >= 380 && w < 440)
                    c = fixed3
                    (
                        -(w - 440.) / (440. - 380.),
                        0.0,
                        1.0
                    );
                else if (w >= 440 && w < 490)
                    c = fixed3
                    (
                        0.0,
                        (w - 440.) / (490. - 440.),
                        1.0
                    );
                else if (w >= 490 && w < 510)
                    c = fixed3
                    (    0.0,
                        1.0,
                        -(w - 510.) / (510. - 490.)
                    );
                else if (w >= 510 && w < 580)
                    c = fixed3
                    (
                        (w - 510.) / (580. - 510.),
                        1.0,
                        0.0
                    );
                else if (w >= 580 && w < 645)
                    c = fixed3
                    (
                        1.0,
                        -(w - 645.) / (645. - 580.),
                        0.0
                    );
                else if (w >= 645 && w <= 780)
                    c = fixed3
                    (    1.0,
                        0.0,
                        0.0
                    );
                else
                    c = fixed3
                    (    0.0,
                        0.0,
                        0.0
                    );

                return saturate(c);
            }

            inline fixed3 bump3 (fixed3 x)
            {
                float3 y = 1 - x * x;
                y = max(y, 0);
                return y;
            }

            fixed3 spectral_gems (float w)
            {
                // w: [400, 700]
                // x: [0,   1]
                fixed x = saturate((w - 400.0)/300.0);
                
                return bump3
                (    fixed3
                    (
                        4 * (x - 0.75),    // Red
                        4 * (x - 0.5),    // Green
                        4 * (x - 0.25)    // Blue
                    )
                );
            }

            fixed3 spectral_spektre (float l)
            {
                float r=0.0,g=0.0,b=0.0;
                        if ((l>=400.0)&&(l<410.0)) { float t=(l-400.0)/(410.0-400.0); r=    +(0.33*t)-(0.20*t*t); }
                else if ((l>=410.0)&&(l<475.0)) { float t=(l-410.0)/(475.0-410.0); r=0.14         -(0.13*t*t); }
                else if ((l>=545.0)&&(l<595.0)) { float t=(l-545.0)/(595.0-545.0); r=    +(1.98*t)-(     t*t); }
                else if ((l>=595.0)&&(l<650.0)) { float t=(l-595.0)/(650.0-595.0); r=0.98+(0.06*t)-(0.40*t*t); }
                else if ((l>=650.0)&&(l<700.0)) { float t=(l-650.0)/(700.0-650.0); r=0.65-(0.84*t)+(0.20*t*t); }
                        if ((l>=415.0)&&(l<475.0)) { float t=(l-415.0)/(475.0-415.0); g=             +(0.80*t*t); }
                else if ((l>=475.0)&&(l<590.0)) { float t=(l-475.0)/(590.0-475.0); g=0.8 +(0.76*t)-(0.80*t*t); }
                else if ((l>=585.0)&&(l<639.0)) { float t=(l-585.0)/(639.0-585.0); g=0.82-(0.80*t)           ; }
                        if ((l>=400.0)&&(l<475.0)) { float t=(l-400.0)/(475.0-400.0); b=    +(2.20*t)-(1.50*t*t); }
                else if ((l>=475.0)&&(l<560.0)) { float t=(l-475.0)/(560.0-475.0); b=0.7 -(     t)+(0.30*t*t); }

                return fixed3(r,g,b);
            }

            inline fixed3 bump3y (fixed3 x, fixed3 yoffset)
            {
                float3 y = 1 - x * x;
                y = saturate(y-yoffset);
                return y;
            }
            fixed3 spectral_zucconi (float w)
            {
                // w: [400, 700]
                // x: [0,   1]
                fixed x = saturate((w - 400.0)/ 300.0);

                const float3 cs = float3(3.54541723, 2.86670055, 2.29421995);
                const float3 xs = float3(0.69548916, 0.49416934, 0.28269708);
                const float3 ys = float3(0.02320775, 0.15936245, 0.53520021);

                return bump3y (    cs * (x - xs), ys);
            }

            fixed3 spectral_zucconi6 (float w)
            {
                // w: [400, 700]
                // x: [0,   1]
                fixed x = saturate((w - 400.0)/ 300.0);

                const float3 c1 = float3(3.54585104, 2.93225262, 2.41593945);
                const float3 x1 = float3(0.69549072, 0.49228336, 0.27699880);
                const float3 y1 = float3(0.02312639, 0.15225084, 0.52607955);

                const float3 c2 = float3(3.90307140, 3.21182957, 3.96587128);
                const float3 x2 = float3(0.11748627, 0.86755042, 0.66077860);
                const float3 y2 = float3(0.84897130, 0.88445281, 0.73949448);

                return
                    bump3y(c1 * (x - x1), y1) +
                    bump3y(c2 * (x - x2), y2) ;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //half3 worldPos = i.wPos;
                //half3 viewDir = normalize(i.wPos - _WorldSpaceCameraPos);
                //return raymarch(worldPos, viewDir);
                fixed4 col;
                col.rgb = spectral_zucconi6(i.uv.x * 300 + 400);
                col.a = 1;
                return col;
            }
            ENDCG
        }
    }
}
