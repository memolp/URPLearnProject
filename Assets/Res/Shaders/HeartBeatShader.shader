// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "QING/HeartBeatShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _V_Scale ("VScale", Range(0, 0.5)) = 0
        _H_Scale ("HScale", Range(0, 0.5)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        //Cull Off

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
            float _H_Scale;
            float _V_Scale;

            v2f vert (appdata v)
            {
                v2f o;

                float h_scale = sin(_Time.y) * 0.2;
                float v_scale = cos(_Time.y) * 0.2 * h_scale;
                float2 xy = float2(v.vertex.x * (1 - h_scale), v.vertex.y * (1 - v_scale));
                float4 vertex = float4(xy, v.vertex.z, v.vertex.w);
                //
                o.vertex = UnityObjectToClipPos(vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
