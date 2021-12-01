Shader "QING/SnakingShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OffsetX1("Offset X1", Range(-0.5, 0.5)) = 0
        _OffsetX2("Offset X2", Range(-0.5, 0.5)) = 0
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
            float _OffsetX1;
            float _OffsetX2;

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
                _OffsetX1 = sin(_Time.y * 20) / 20;
                _OffsetX2 = sin(_Time.y * 10) / 100;
                fixed4 col = fixed4(1, 1,1, 1);
                // sample the texture
                fixed4 scol = tex2D(_MainTex, i.uv + float2(_OffsetX2, 0));
                float2 uv = i.uv + float2(_OffsetX1, 0);

                col.rgb = tex2D(_MainTex, uv).rgb;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col * 0.9 + scol * 0.5;
            }
            ENDCG
        }
    }
}
