Shader "QING/VideoPlayer"
{
    Properties
    {
        _MainTex  ("Noise Texture", 2D) = "white" {}
        _Threshold ("Threshold", Range(0, 1)) = 0
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

            // sampler2D _CameraDepthTexture;
            float _Threshold;

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
                // return Luminance(col1);
                float val = Luminance(col1);
                return lerp(col1, fixed4(0., 0., 0., 0.), val * _Threshold);
               // fixed4 val = ceil(saturate(col1.g - col1.r - _Threshold)) * ceil(saturate(col1.g - col1.b - _Threshold));
                // return lerp(col1, fixed4(0., 0., 0., 0.), val);
            }
            ENDCG
        }
    }
}
