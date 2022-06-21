Shader "QING/LLambortShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Ramp("Shadow Ramp", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        [HDR]_RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimPower ("Rim Power", float) = 1
        _ShadowSmoothness("Shadow Smooth", Range(0, 1)) = 0.1
        _ShadowColor("Shadow Color", Color) = (1,1,1,1)
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
			#include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 worldNormal : NORMAL;
                float3 worldPosition:TEXCOORD2;
				float3 viewDir : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
			float4 _Color;
			float _Antialiasing;
			float _Glossiness;
            float _Fresnel;
		    sampler2D _LightingRamp;
            float4 _RimColor;
            float _RimPower;
            fixed _ShadowSmoothness;
            float4 _ShadowColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 模型顶点-世界坐标
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
				o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            float _OutlineSize;
            fixed4 _OutlineColor;
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldPosition = normalize(i.worldPosition);

				fixed4 albedo = tex2D(_MainTex, i.uv) * _Color;
               

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.rgb;
                UNITY_LIGHT_ATTENUATION(atten, i, worldPosition);

				half nDotL = dot(worldNormal, _WorldSpaceLightPos0.xyz);
                // Lambert 
                
                fixed3 r = tex2D(_Ramp,  fixed2(nDotL*0.5+0.5, 0.5));
                nDotL = max(0, nDotL);
                // nDotL = nDotL * 0.5 + 0.5;  //half Lambert
                //albedo.rgb = albedo.rgb * _LightColor0.rgb * nDotL;
                half3 h = normalize((_WorldSpaceLightPos0.xyz + viewDir)*0.5);
                half nDotH = max(0,dot(worldNormal, h) );

                half nDotV = dot(worldNormal, viewDir);

                half v = nDotL * pow(nDotL * nDotV, 1-atten) * atten;

                half rim = 1 - dot(viewDir, worldNormal);

                float spec = pow(nDotH, _Glossiness* 128.0) * 0.5;
                fixed4 col = fixed4(1,1,1,1);
                float shadow = smoothstep(0, _ShadowSmoothness, nDotL);
                col.rgb = albedo.rgb * _LightColor0.rgb * r;//lerp(_ShadowColor.rgb, col.rgb, r);// lerp(_ShadowColor.rgb, col.rgb, shadow) ;//*  r * nDotL;//smoothstep(0, r, nDotL);
                col.rgb += _LightColor0.rgb * spec;
                col.rgb += _RimColor.rgb * step(1,pow(rim, _RimPower));
                //col.rgb += unity_AmbientSky.rgb;
                col.a = albedo.a;

                return col;


			// 	// float delta = fwidth(diffuse) * _Antialiasing;
			// 	// float diffuseSmooth = smoothstep(0, delta, diffuse);
            //     float3 diffuseSmooth = tex2D(_LightingRamp, float2(diffuse * 0.5 + 0.5, 0.5));

			// 	float3 halfVec = normalize(_WorldSpaceLightPos0 + i.viewDir);
			// 	float specular = dot(normal, halfVec);
			// 	specular = pow(specular * diffuseSmooth, _Glossiness);

			// 	float specularSmooth = smoothstep(0, 0.01 * _Antialiasing, specular);

			// 	float rim = 1 - dot(normal, i.viewDir);
            //     rim = rim * pow(diffuse, 0.3);
            //     float fresnelSize = 1 - _Fresnel;

            //     float rimSmooth = smoothstep(fresnelSize, fresnelSize * 1.1, rim);

            //     float3 col = albedo * ((diffuseSmooth + specularSmooth + rimSmooth) * _LightColor0 + unity_AmbientSky);
               
            //     return float4(col, albedo.a);

            //     // 描边功能 这种不好呀。。。。。
            //    float edgeValue = step(0, dot(i.viewDir, normal) - _OutlineSize);
            //    return lerp(_OutlineColor, float4(col, albedo.a), edgeValue);
            }

            ENDCG
        }

    }
    FallBack "Diffuse"
}
