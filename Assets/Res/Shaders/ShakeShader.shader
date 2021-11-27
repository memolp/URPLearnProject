Shader "QING/ShakeShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale("Scale", Range(0,1)) = 0
        _Scale2("Scale2", Range(0, 1)) = 0
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
            float _Scale;
            float _Scale2;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 原图采样
                fixed4 col = tex2D(_MainTex, i.uv);
                // 两次对纹理进行偏移采样
                fixed4 offCol1 = tex2D(_MainTex, i.uv - _Scale);
                fixed4 offCol2 = tex2D(_MainTex, i.uv - _Scale2);
                // 混合原图，和两次偏移的颜色 - 也就是单通道的颜色进行了偏移
                fixed3 blendColor = fixed3(offCol2.r, col.g, offCol1.b);
                return fixed4(blendColor, col.a);
            }
            ENDCG
        }
    }
}
