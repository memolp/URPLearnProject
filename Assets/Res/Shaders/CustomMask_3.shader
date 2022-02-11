Shader "QING/CustomMask03"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Frequency ("Frequency", float) = 20
        _Fill ("Fill", Range(0, 1)) = 0.8
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True"}
        LOD 100
        Cull Off
        ZWrite Off
        ZTest Always
        
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
                float2 uv:TEXCOORD0;
                float4 vertex: SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float _Frequency;
            float _Fill;

            float random(float2 input)
            {
                return frac(sin(dot(input, float2(12.9898,78.233)))* 43758.5453123);
            }

            /*fixed4 frag(v2f i):SV_Target
            {
                // 1. 将uv.y 放大_Frequency 倍。
                // 2. 进行随机产生一个数
                // 3. 如果这个数 大于 _Fill 待填充的数就 返回1， 否则返回0
                // 4. 通过 1 - 结果进行反转
                float stripes = 1 - step(_Fill, random( floor(i.uv.y * _Frequency)));
                return float4(stripes, stripes, stripes, 1);
            }*/

            fixed4 frag(v2f i):SV_Target
            {
                float4 red = fixed4(1, 0, 0, 1);
                float4 green = fixed4(0, 1, 0, 1);
                float sinY = sin(i.uv.y * _Frequency); // [-1, 1]
                sinY = (sinY + 1) * 0.5; // [0, 1]
                float4 waveY = lerp(red, green, sinY);

                float offsetV = 0.01;
                // 如果是红色返回offsetV， 否则返回-offsetV
                float x = waveY.x * offsetV - waveY.y * offsetV;

                return tex2D(_MainTex, i.uv + fixed2(x, 0));
            }
            ENDCG
        }
    }
}