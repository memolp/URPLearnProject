Shader "QING/FireShader"
{
    Properties
    {
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _GradientTex ("Gradient Texture", 2D) = "white" {}
        _FireUpColor ("Up Color", Color) = (1,1,1,1)
        _FireCenterColor ("Center Color", Color) = (1,1,1,1)
        _FireBottomColor ("Botton Color", Color) = (1,1,1,1)
        _FireUpOffset ("Up Offset", float) = 1
        _FireCenterOffset ("Center Offset", float) = 1
        _FireBottomOffset ("Bottom Offset", float) = 1
    }
    SubShader
    {
        // Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        // Cull Off
        // Blend SrcAlpha OneMinusSrcAlpha
        // LOD 100

        Tags { "RenderType"="Opaque"}
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

            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            sampler2D _GradientTex;

			float4 _FireUpColor;
            float4 _FireCenterColor;
            float4 _FireBottomColor;

			float _FireUpOffset;
			float _FireCenterOffset;
            float _FireBottomOffset;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 uv = i.uv;
                uv.y += _Time.y;
                fixed y = tex2D(_NoiseTex, uv); // 扭曲图
                fixed x = tex2D(_GradientTex, i.uv).r; // 渐变图

                fixed L1 = step(y, x - _FireUpOffset);  // 通过y,x获得第一层火焰
                fixed L2 = step(y, x - _FireCenterOffset); // 第二层
                fixed L3 = step(y, x - _FireBottomOffset); // 第三层
                fixed4 col = lerp(_FireCenterColor, _FireUpColor, L1-L2); // 第一层和第二层的插值
                col = lerp(_FireBottomColor, col, L1-L3); // 第二层和第三层的插值，然后*L1 过滤无效部分。
                // 透明效果
                if(L1 < 0.001)
                    discard;
                return col;

            }
            ENDCG
        }
    }
}
