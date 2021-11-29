Shader "QING/RainDrop"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RainDrop ("RainDrop", 2D) = "white" {}
        _Speed ("Speed", Range(0, 5)) = 0
        _RainColor ("Rain Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

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
                float2 duv: TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _RainDrop;
            float4 _MainTex_ST;
            float4 _RainDrop_ST;
            float _Speed;
            float4 _RainColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.duv = TRANSFORM_TEX(v.uv, _RainDrop);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float lerp_t = frac(_Time.y * _Speed); // 0 - 0.999
                float t = 1 - lerp_t; // 1. 0.001
                float t2 = 1 - frac((_Time.y) * _Speed + 0.5); // 时间偏移一点点
                fixed3 texColor = tex2D(_RainDrop,i.duv);
                fixed3 texColor2 = tex2D(_RainDrop,i.duv + float2(0.5,0.5)); // uv 偏移一点点
                float dis = saturate(1-distance(texColor.r - t,0.05)/0.05);
                float dis2 = saturate(1-distance(texColor2.r - t2,0.05)/0.05);
                fixed3 col = fixed3(dis,dis,dis);
                fixed3 col2 = fixed3(dis2,dis2,dis2);
                float lerp_t2 = sin(lerp_t * 3.14159); // 把 [0,1] 映射到 [0,3.14159] 得到 sin 的半个周期，所以并不需要 abs
                fixed3 mainCol = tex2D(_MainTex, i.uv).rgb;
                fixed3 finalCol = lerp(col2,col,lerp_t2) *_RainColor + mainCol;
                UNITY_APPLY_FOG(i.fogCoord, finalCol);
                return fixed4(finalCol,1);
            }
            ENDCG
        }
    }
}
