Shader "QING/NoiseEffect02"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _DisplGuide("Displacement guide", 2D) = "white" {}
        _DisplAmount("Displacement amount", float) = 0
        [HDR]_ColorBottomDark("Color bottom dark", color) = (1,1,1,1)
        [HDR]_ColorTopDark("Color top dark", color) = (1,1,1,1)
        [HDR]_ColorBottomLight("Color bottom light", color) = (1,1,1,1)
        [HDR]_ColorTopLight("Color top light", color) = (1,1,1,1)
        _BottomFoamThreshold("Bottom foam threshold", Range(0,1)) = 0.1
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
                float2 noiseUV : TEXCOORD1;
                float2 displUV : TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            sampler2D _DisplGuide;
            float4 _DisplGuide_ST;
            fixed4 _ColorBottomDark;
            fixed4 _ColorTopDark;
            fixed4 _ColorBottomLight;
            fixed4 _ColorTopLight;
            half _DisplAmount;
            half _BottomFoamThreshold;


            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.noiseUV = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.displUV = TRANSFORM_TEX(v.uv, _DisplGuide);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag(v2f i):SV_Target
            {
                // 波浪扭曲
                half2 displ = tex2D(_DisplGuide, i.displUV + _Time.y / 5).xy;
                displ = ((displ * 2) - 1) * _DisplAmount;
                 
                //Noise 位移下落
                half noise = tex2D(_NoiseTex, float2(i.noiseUV.x, i.noiseUV.y + _Time.y / 5) + displ).x; //[0,1]
                // 实现间隔0.2 取值{0.0, 0.2, 0.4、0.6、0.8、1.0}
                noise = round(noise * 5.0) / 5.0; // [0,5.0] / 5.0

                // 颜色插值 
                fixed4 col = lerp(lerp(_ColorBottomDark, _ColorTopDark, i.uv.y), lerp(_ColorBottomLight, _ColorTopLight, i.uv.y), noise);
                col = lerp(fixed4(1,1,1,1), col, step(_BottomFoamThreshold, i.uv.y + displ.y));
                return col;
            }
            ENDCG
        }
    }
}