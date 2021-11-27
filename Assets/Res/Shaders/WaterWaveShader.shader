Shader "QING/WaterWaveShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Distort ("_Distort", 2D) = "white" { }
        _Force ("_Force", Range(0,1)) = 0
        _Spd ("_Spd", Range(0,5)) = 0
        _High ("_High", Range(0,2)) = 0
        _offsetU("_offsetU", Range(0, 2)) = 1.2
        _offsetV("_offsetV", Range(0, 2)) = 1.2
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
            sampler2D _Distort;
            float _Force;
            float _Spd;
            float _High;
            float _offsetV;
            float _offsetU;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //float4 color_Tex = tex2D(_MainTex,i.uv);
                //扰动采样 多向波纹叠加
                float2 l_uv = float2(-_Spd*_Time.x*_offsetU, _offsetV*-_Spd*_Time.x);
                float2 r_uv = float2(_Spd*_Time.x*_offsetU, _offsetV*_Spd*_Time.x);
                float4 distort = tex2D(_Distort,i.uv + l_uv);
                float4 distort2 = tex2D(_Distort,i.uv + r_uv);
                //贴图扰动采样
                float2 n_uv = i.uv + _Force * float2(distort.r + distort2.r - _High, distort.g + distort2.g - _High);
                float4 color_Distort = tex2D(_MainTex, n_uv); 
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return color_Distort;
            }
            ENDCG
        }
    }
}
