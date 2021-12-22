Shader "QING/FurShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Tex", 2D) = "white" {}
        _FurOffset("Fur Offset", Range(0, 20)) = 1
        _UVOffset ("UV Offset", Vector) = (0, 0, 0.2, 0.2)
        _SubTexUV ("Sub Tex UV", Vector) = (1, 1, 1, 1)
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Color ("Color", Color) = (1, 1, 1, 1)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
             Tags { "LightMode" = "LightweightForward"}
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
                float3 normal : NORMAL;
                float4 color: COLOR;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 color: COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D  _NoiseTex;
            float _FurOffset;
            float4 _UVOffset;
            float4 _SubTexUV;
            float4 _BaseColor;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                float3 aNormal = v.normal.xyz;
                aNormal.xyz += _FurOffset;
                float3 n = aNormal * _FurOffset * (_FurOffset * saturate(v.color.a));

                float2 uvOffset = _UVOffset.xy * _FurOffset;
                uvOffset *= 0.1;
                float2 uv1 = TRANSFORM_TEX(v.uv, _MainTex) + uvOffset *  (float2(1,1)/_SubTexUV.xy);
                float2 uv2 = TRANSFORM_TEX(v.uv, _MainTex )*_SubTexUV.xy   + uvOffset;

                o.uv = float4(uv1,uv2);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = n;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 color = fixed4(1.0, 1.0, 1.0, 1.0);

                // half3 base = tex2D(_MainTex, i.uv.xy).rgb;
                for (int s = 0; s < 50; s++)
                {
                    float scale = 1.0f - 1/ (50 - s);
                    color.xyz += tex2D(_MainTex,  scale + i.uv.xy).xyz / float(50);
                }
               // half3 NoiseTex = tex2D(_MainTex, i.uv.xy).rgb;

                //half Noise = NoiseTex.r;

                //color.rgb = i.color.rgb; //lerp(_Color,_BaseColor,_FurOffset) ;
                // color.rgb = lerp(_Color,base,_FurOffset) ;
                //color.rgb = _BaseColor;

                //color.a = saturate(Noise-_FurOffset) ;
                //clip(color.a);
                return  color;
            }
            ENDCG
        }

        // Pass
        // {
        //      Tags { "LightMode" = "UniversalForward"}
        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     // make fog work
        //     #pragma multi_compile_fog

        //     #include "UnityCG.cginc"

        //     struct appdata
        //     {
        //         float4 vertex : POSITION;
        //         float2 uv : TEXCOORD0;
        //         float3 normal : NORMAL;
        //         float4 color: COLOR;
        //     };

        //     struct v2f
        //     {
        //         float4 uv : TEXCOORD0;
        //         UNITY_FOG_COORDS(1)
        //         float4 vertex : SV_POSITION;
        //     };

        //     sampler2D _MainTex;
        //     float4 _MainTex_ST;
        //     sampler2D  _NoiseTex;
        //     float _FurOffset;
        //     float4 _UVOffset;
        //     float4 _SubTexUV;
        //     float4 _BaseColor;
        //     float4 _Color;

        //     v2f vert (appdata v)
        //     {
        //         v2f o;
        //         float3 aNormal = v.normal.xyz;
        //         aNormal.xyz += _FurOffset;
        //         float3 n = aNormal * _FurOffset * (_FurOffset * saturate(v.color.a));

        //         float2 uvOffset = _UVOffset.xy * _FurOffset;
        //         uvOffset *= 0.1;
        //         float2 uv1 = TRANSFORM_TEX(v.uv, _MainTex) + uvOffset *  (float2(1,1)/_SubTexUV.xy);
        //         float2 uv2 = TRANSFORM_TEX(v.uv, _MainTex )*_SubTexUV.xy   + uvOffset;

        //          // 放大模型-基于法线方向
        //         v.vertex.xyz += normalize(v.normal) * 0.001;
        //         o.vertex = UnityObjectToClipPos(v.vertex);

        //         o.uv = float4(uv1,uv2);
        //        // o.vertex = UnityObjectToClipPos(v.vertex);
        //         UNITY_TRANSFER_FOG(o,o.vertex);
        //         return o;
        //     }

        //     fixed4 frag (v2f i) : SV_Target
        //     {
        //         fixed4 color = fixed4(1.0, 1.0, 1.0, 1.0);

        //         // half3 base = tex2D(_MainTex, i.uv.xy).rgb;

        //         half3 NoiseTex = tex2D(_MainTex, i.uv.zw).rgb;

        //         half Noise = NoiseTex.r;

        //         color.rgb = lerp(_Color,_BaseColor,_FurOffset) ;
        //         // color.rgb = lerp(_Color,base,_FurOffset) ;
        //         //color.rgb = _BaseColor;
                
        //         color.a = Noise;//saturate(Noise-_FurOffset) ;
        //         clip(1- color.a);
        //         return color;
        //     }
        //     ENDCG
        // }

    }
}
