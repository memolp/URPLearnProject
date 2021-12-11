Shader "QING/ScreenBreakShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BreakBumpTex ("Break Bump Text", 2D) = "bump" {}
        _BreakBumpScale ("Break Bump Scale", Range(0, 1)) = 1.0
        _SatCount("Sat Count", Range(0, 1)) = 0.0
        _Strength("Strength", Range(0, 1)) = 0.2
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
            sampler2D _BreakBumpTex;
            float _BreakBumpScale;
            float _SatCount;
            float _Strength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 packedNoraml = tex2D(_BreakBumpTex, i.uv);
                fixed3 tangetNoraml = UnpackNormal(packedNoraml);
                tangetNoraml.xy *= _BreakBumpScale;
                // 采样
                fixed4 col = tex2D(_MainTex, i.uv + tangetNoraml.xy * _Strength);
                // 变灰
                fixed4 luminance = Luminance(col);
                fixed4 finalCol = lerp(luminance, col, _SatCount);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, finalCol);
                return finalCol;
            }
            ENDCG
        }
    }
}
