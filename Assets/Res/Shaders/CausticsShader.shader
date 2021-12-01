Shader "QING/CausticsShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CausticTex ("Caustic", 2D) = "white" {}
        _CausticVer ("Caustics Vector", Vector) = (1, 1, 1, 1)
        _CausticSpeed ("Caustic Speed", Range(0, 5)) = 0
        _FlowSpeed ("Flow Speed", Range(0, 5)) = 0
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
            sampler2D _CausticTex;
            float4 _MainTex_ST;
            float4 _CausticVer;
            float _CausticSpeed;
            float _FlowSpeed;

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
                // 焦散uv
                float2 caustic_uv = i.uv * _CausticVer.xy  + _CausticSpeed * _Time.y;
                // 水波纹uv，使用_CausticVer的zw作为uv的偏移值
                float2 l_uv = float2(-_FlowSpeed * _Time.x * _CausticVer.z, _CausticVer.w * -_FlowSpeed * _Time.x);
                float2 r_uv = float2(_FlowSpeed * _Time.x * _CausticVer.z, _CausticVer.w * _FlowSpeed * _Time.x);
                // 采样生成光影效果，只使用r通道
                float r = tex2D(_CausticTex, caustic_uv).r;
                // 采样生成波纹，使用gb两个通道。
                float4 dis1 = tex2D(_CausticTex, i.uv + l_uv);
                float4 dis2 = tex2D(_CausticTex, i.uv + r_uv);
                // 波纹扰动采样UV
                float2 uv = i.uv + 0.032 * float2(dis1.g + dis2.g - 0.2, dis1.b + dis2.b - 0.2);
                fixed4 col = tex2D(_MainTex, uv);
                // 平滑插值光影效果
                fixed3 cc = lerp(col.rgb  * (r + 0.8), col.rgb, 0.5);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return fixed4(cc, col.a);
            }
            ENDCG
        }
    }
}
