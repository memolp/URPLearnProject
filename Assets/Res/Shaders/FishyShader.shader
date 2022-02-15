Shader "QING/FishyShader"
{
    // 后处理效果，鱼眼效果
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BarrelPower("Barrel Power", Float) = 1.0
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform float _BarrelPower;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // 制作失真的鱼眼效果的uv
            float2 distort(float2 pos)
            {
                float theta = atan2(pos.y, pos.x);
                float radius = length(pos);
                radius = pow(radius, _BarrelPower);
                pos.x = radius * cos(theta);
                pos.y = radius * sin(theta);

                return 0.5 * (pos + 1.0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
               float2 xy = 2.0 * i.uv - 1.0; // [0,1] ==> [-1, 1]
               float d = length(xy);
                if (d >= 1.0)  // 丢弃uv大于1的地方
                {
                    discard;
                }
                // 进行uv调整
                float2 uv = distort(xy);
                // 采样
                return tex2D(_MainTex, uv);
            }
            ENDCG
        }
    }
}
