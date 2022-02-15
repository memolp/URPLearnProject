Shader "QING/PaintingShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 1表示3x3 2表示5x5
        [IntRange]_Radius ("采样半径", Range(1, 10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

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
            float4 _MainTex_ST;
            float2 _MainTex_TexelSize;
            int _Radius;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            struct region
            {
                float3 mean;
                float variance;
            };

            region cell_sample(float2 uv, int4 fromto, int samples)
            {
                region r;
                float3 totalColor = float3(0,0,0);
                float3 totalSquareColor = float3(0,0,0);

                for(int x=fromto.x; x <= fromto.z; x++)
                {
                    for(int y=fromto.y; y<= fromto.w; y++)
                    {
                        float2 offset = float2(x * _MainTex_TexelSize.x, y * _MainTex_TexelSize.y);
                        fixed3 col = tex2D(_MainTex, uv + offset).rgb;
                        totalColor += col;
                        totalSquareColor += col * col;
                    }
                }
                float3 avg = totalColor / samples;
                float3 squareAvg = abs(totalSquareColor / samples - (avg * avg));
                r.mean = avg;
                r.variance = length(squareAvg);
                return r;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                // 通过半径计算整体的采样 1=3x3 2=5x5 3=7x7 4=9x9
                int size_r = _Radius * 2 + 1;
                
                int upper = (size_r - 1) / 2;
                int lower = -upper;
                int samples = (upper + 1) * (upper + 1);

                region A = cell_sample(i.uv, int4(lower, lower, 0, 0), samples);
                region B = cell_sample(i.uv, int4(0, lower, upper, 0), samples);
                region C = cell_sample(i.uv, int4(lower, 0, 0, upper), samples);
                region D = cell_sample(i.uv, int4(0, 0, upper, upper), samples);

                float squareValue =  A.variance;
                float3 avgColor = A.mean;

                int v = step(B.variance, squareValue);
                squareValue = lerp(squareValue, B.variance, v);
                avgColor = lerp(avgColor, B.mean, v);

                v = step(C.variance, squareValue);
                squareValue = lerp(squareValue, C.variance, v);
                avgColor = lerp(avgColor, C.mean, v);

                v = step(D.variance, squareValue);
                squareValue = lerp(squareValue, D.variance, v);
                avgColor = lerp(avgColor, D.mean, v);

                 //get regular color
                fixed4 col = fixed4(avgColor, 1);

                return col;
            }
            ENDCG
        }
    }
}
