Shader "QING/GeometricColor"
{
    Properties
    {
        _MainTex  ("Main Texture", 2D) = "white" {}
        _RampTex  ("Ramp Texture", 2D) = "white" {}
        _Speed    ("Speed", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        // Tags { "RenderType"="Opaque"}
        // LOD 100

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
                float3 worldPos: TEXCOORD1;
                float4 screenPos: TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _RampTex;
            float _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex );
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col1 = tex2D(_MainTex, i.uv);
                fixed4 ramp = tex2D(_RampTex, fixed2(col1.r + _Time.y * _Speed, 0.5));
                ramp.a = 1 - col1.r;
                return ramp;
               
            }
            ENDCG
        }
    }
}
