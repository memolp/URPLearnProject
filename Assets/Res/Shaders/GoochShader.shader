Shader "QING/GoochShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        reflectionTex ("reflectionTex", Cube) = "white" {}
        _Color  ("Color", Color) = (1,1,1,1)
        _WarmColor ("WarmColor", Color) = (1,1,1,1)
        _HightColor ("HightColor", Color) = (1,1,1,1)
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
            float4 _WarmColor;
            float4 _HightColor;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 模型顶点-世界坐标
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                // 法线 - 世界坐标
                o.worldNormal =UnityObjectToWorldNormal(v.normal);// mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz;

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed3 lit(fixed3 l, fixed3 n, fixed3 v)
            {
                fixed3 r_l = reflect(-l, n);
                float s = saturate(100.0 * dot(r_l, v) - 97.0);
                return lerp(_WarmColor.rgb, _HightColor.rgb, s);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPosition = normalize(i.worldPosition);
                float3 worldNormal = normalize(i.worldNormal);
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPosition));
                float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPosition));

                float4 outColor = tex2D(_MainTex, i.uv);

                // 漫反射-gooch
                float gooch = (1.0 + dot(worldLightDir, worldNormal)) / 2.0;
                float3 kCool = _Color.rgb + 0.25 * outColor.rgb;
                float3 kWarm = _WarmColor.rgb + 0.25 * outColor.rgb;
                float3 goochDiffuse = gooch * kWarm + ( 1 - gooch) * kCool;

                // 镜面反射 高光
                float3 refelctDir = reflect(-worldLightDir, worldNormal);
                float  spec = clamp(dot(worldViewDir, refelctDir), 0, 1);
                spec = pow(spec, 5);
                float3 specular = _HightColor * spec;

                return float4(goochDiffuse + specular, 1);

            }
            ENDCG
        }
    }
}
