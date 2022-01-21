Shader "QING/RefractionShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        reflectionTex ("reflectionTex", Cube) = "white" {}
        _Color  ("Color", Color) = (1,1,1,1)
        _refractionRatio ("refractionRatio", Range(0, 10)) = 1
        _mirrorRefraction ("mirrorRefraction", Range(0, 1)) = 0.2
    }
    SubShader
    {
        Tags { 
            "Queue" = "Transparent"
			"RenderType" = "Transparent"
			"IgnoreProjector" = "True"
        }
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
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float3 worldPosition:TEXCOORD2;
                float3 worldNormal:TEXCOORD3;

                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            samplerCUBE reflectionTex;
            float4 _MainTex_ST;
            float _refractionRatio;
            float _mirrorRefraction;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 模型顶点-世界坐标
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                // 法线 - 世界坐标
                o.worldNormal = mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz;

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               float3 worldPosition = normalize(i.worldPosition);
               float3 worldNormal = normalize(i.worldNormal);
               float3 worldViewDir = -(UnityWorldSpaceViewDir(i.worldPosition));
               
               float3 vRefract = refract(worldViewDir, worldNormal, _refractionRatio);
            
               float x = _mirrorRefraction * vRefract.x;
               float3 cr = texCUBE(reflectionTex, float3(x, vRefract.yz)).rgb;
              
               fixed4 c = fixed4(cr, 1.0);

               return c;
            }
            ENDCG
        }
    }
}
