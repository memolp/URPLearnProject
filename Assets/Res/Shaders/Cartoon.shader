Shader "QING/Cartoon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BackTex ("Texture", 2D) = "white" {}
        _Radius ("Radius", Range(1, 2000)) = 2
        _Transparent ("Transparent", Range(0,1)) = 0.5
        _Color  ("Color", Color) = (1,1,1,1)
        _FallOff ("FallOf", Range(0, 5)) = 0.1
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
            float4 _MainTex_ST;
            float2 _MainTex_TexelSize;
            float _Transparent;
            sampler2D _BackTex;
            float _Radius;
            fixed4 _Color;
            float _FallOff;

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
            #define PI 3.14159265359
            #define PI2 6.283185307

            #define COLOR_SAVE_NUM 5
            #define _Columns 100
            #define _Rows 100
            fixed4 frag (v2f i) : SV_Target
            {
               float3 worldPosition = normalize(i.worldPosition);
               float3 worldNormal = normalize(i.worldNormal);
               float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPosition));
               float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPosition));
               float colordiff = 0.1;
               float3 abledo = tex2D(_MainTex, i.uv).rgb;
               float3 unlitColor = abledo  ;//- colordiff;
               float3 specularColor = abledo + colordiff;
               float brightness = dot(worldNormal, worldLightDir);
               float3 reflecttance = normalize(2.0 * dot(worldLightDir, worldNormal)* worldNormal - worldLightDir);
               float cw = dot(worldViewDir, worldNormal);
               if(cw < 0.3)
               {
                   return float4(0,0,0,1);
               }
               if(brightness  > 0)
               {
                   if(length(worldViewDir - reflecttance) < 0.6)
                   {
                       if(length(worldNormal - reflecttance) > 0.2)
                       {
                           return float4(specularColor, 1.0);
                       }
                   }
                   return float4(unlitColor, 1.0);;
               }
               return float4(unlitColor, 1.0);
            }
            ENDCG
        }
    }
}
