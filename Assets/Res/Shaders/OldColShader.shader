Shader "QING/OldColShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            // With other variable definitions.
            static const float EPSILON = 1e-10;
            fixed4 frag (v2f i) : SV_Target
            {
                // 主纹理采样
                fixed4 tex = tex2D(_MainTex, i.uv);
                // 对各个通道的颜色进行处理（这里*4的结果最大为3.9999，因为减去了很小的EPSILON）
                int r = (tex.r - EPSILON) * 4;
                int g = (tex.g - EPSILON) * 4;
                int b = (tex.b - EPSILON) * 4;
                // 将通道颜色设置到[0,1]范围内，并返回
                return float4(r / 3.0, g / 3.0, b / 3.0, 1.0);
            }
            ENDCG
        }
    }
}
