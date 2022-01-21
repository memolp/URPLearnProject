Shader "QING/Cartoon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Ramp ("Texture", 2D) = "white" {}
        _Color  ("Color", Color) = (1,1,1,1)
        _EdgeColor("Edge Color", Color) = (1,1,1,1)
        _Specular ("Specular Color", Color) = (1,1,1,1)
        _SpecularScale ("Specular Scale", Range(0, 10)) = 1
        _EdgeThreshold ("Edge Threshold", Range(0, 1)) = 0.2
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
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

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
            sampler2D _Ramp;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _SpecularScale;
            float _EdgeThreshold;
            fixed4 _EdgeColor;
            fixed4 _Specular;

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
               
               float3 worldNormal = normalize(i.worldNormal);
               float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPosition));
               float3 worldPosition = normalize(i.worldPosition);
               float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPosition));
               float3 worldHalfDir = normalize(worldLightDir + worldViewDir);

               fixed4 c = tex2D(_MainTex, i.uv);
               fixed3 abledo = c.rgb * _Color.rgb;

               fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abledo;
               UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosition);

               fixed diff = dot(worldNormal, worldLightDir);
               diff = (diff * 0.5 + 0.5)*atten;

               fixed3 diffuse = _LightColor0.rgb * abledo * tex2D(_Ramp, float2(diff, diff)).rgb;
               fixed spec = dot(worldNormal, worldHalfDir);
               fixed w = fwidth(spec) * 3.0;
               
               fixed spvalue = smoothstep(-w,w,spec-(1-_SpecularScale)) * step(0.0001,_SpecularScale);
               fixed3 specular = _Specular.rgb * spvalue;
               fixed4 color = fixed4(ambient + diffuse + specular, 1.0);

                // 描边功能
               float edgeValue = step(0, dot(worldViewDir, worldNormal) - _EdgeThreshold);
               return lerp(_EdgeColor, color, edgeValue);
            }
            ENDCG
        }
    }
}
