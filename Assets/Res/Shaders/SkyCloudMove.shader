Shader "QING/SkyCloudMove"
{
    Properties
    {
        _CloudTex ("Cloud Texture", 2D) = "white" {}
        _CloudTex2 ("Cloud Texture2", 2D) = "white" {}
        _CloudTex3 ("Cloud Texture3", 2D) = "white" {}
        _MoveSpeed("Move Speed", Vector) = (0.2, 0.3, 0.15, 1.0)
        _SkyColor("Sky Color", Color) = (1.0, 1.0, 1.0, 1.0)
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
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float4 vertex : SV_POSITION;
            };

            sampler2D _CloudTex;
            sampler2D _CloudTex2;
            sampler2D _CloudTex3;
            float4 _CloudTex_ST;
            float4 _CloudTex2_ST;
            float4 _CloudTex3_ST;
            float4 _MoveSpeed;
            float4 _SkyColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _CloudTex);
                o.uv2 = TRANSFORM_TEX(v.uv, _CloudTex2);
                o.uv3 = TRANSFORM_TEX(v.uv, _CloudTex3);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 针对3个采样，并按速度移动UV的x
                fixed4 col = tex2D(_CloudTex, i.uv + fixed2(_Time.x * _MoveSpeed.x, 0));
                fixed4 col2 = tex2D(_CloudTex2, i.uv2 + fixed2(_Time.x * _MoveSpeed.y, 0));
                fixed4 col3 = tex2D(_CloudTex3, i.uv3 + fixed2(_Time.x * _MoveSpeed.z, 0));
                // 取三个中值最大的作为当前的效果计算
                fixed avga = max(max(col.a , col2.a) ,col3.a) ;
                // 与天空颜色进行插值
                fixed3 finalColor = lerp(_SkyColor.rgb, fixed3(1.0,1.0,1.0), avga);
                return fixed4(finalColor , 1.0);
            }
            ENDCG
        }
    }
}
