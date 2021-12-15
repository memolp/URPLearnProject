// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "QING/SeqAnimate" 
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _CloudTex("噪声",2D) ="white"{}
        _Value("value", Range(0, 50)) = 1
        _SizeX("SizeX", float) = 4
        _SizeY("SizeY", float) = 4
        _Speed("Speed", float) = 200
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" 
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _CloudTex;
            float4 _CloudTex_ST;
            float _Value;
            float _SizeX;
            float _SizeY;
            float _Speed;

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half2 texcoord : TEXCOORD0;
            };

            v2f vert(appdata_t IN)
            {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(IN.vertex);
                OUT.texcoord = TRANSFORM_TEX(IN.texcoord, _CloudTex);
                return OUT;
            }

           

            fixed4 frag(v2f IN) : SV_Target
            {
                // 方法1获取序列帧x，y的偏移
               /* int indexX = fmod(_Time.x * _Speed, _SizeX);
                int indexY = fmod((_Time.x * _Speed) / _SizeX, _SizeY);*/

                // 方法2 计算序列帧x，y的偏移
                int index = floor(_Time.x * _Speed);
                int indexY = index / _SizeX;
                int indexX = index - indexY * _SizeX;

                // 先对序列帧图进行按行列进行裁剪
                fixed2 uv = float2(IN.texcoord.x / _SizeX, IN.texcoord.y / _SizeY);
                uv.x += indexX / _SizeX;  // 每帧更新位置
                uv.y -= indexY / _SizeY;

                fixed4 color = tex2D(_CloudTex, uv);
                clip(color.a - 0.1);
                // if(color.a < 0.1)
                //     discard;
                return color;
            }
            ENDCG
        }
    }
}