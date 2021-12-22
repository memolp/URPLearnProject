Shader "QING/BlurLight" 
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _BlurDistance("BlurDistance", range(0, 10)) = 4
        _SpecularPower("SpecularPower", Range(0, 10)) = 4
        _LightDirection("LightDirection", Vector) = (0.5,0.5,0,0)
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

            #define NUM_SAMPLES 100

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _BlurDistance;
            float _SpecularPower;
            fixed4 _LightDirection;

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
                OUT.texcoord = TRANSFORM_TEX(IN.texcoord, _MainTex);
                return OUT;
            }

           
           
            fixed4 frag(v2f IN) : SV_Target
            {
                 //1
                fixed4 color = fixed4(0.0f, 0.0f, 0.0f, 1.0f);
                //2
                float2 ray = IN.texcoord - _LightDirection.xy;//_LightDirection.xy;

                //3
                for (int i = 0; i < NUM_SAMPLES; i++)
                {
                    float scale = 1.0f - _BlurDistance * (float(i) / float(NUM_SAMPLES - 1));
                    color.xyz += tex2D(_MainTex, (ray * scale) +  _LightDirection.xy).xyz / float(NUM_SAMPLES);
                }

                //4
                return color * _SpecularPower;
            }
            ENDCG
        }
    }
}