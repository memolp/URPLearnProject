
Shader "QING/CrystalShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR]_Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Glossiness", float) = 1
        [HDR]_SpecalColor ("Spec Color", Color) = (1,1,1,1)
        [HDR]_RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimPower ("Rim Power", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

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
            float4 _SpecalColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 模型顶点-世界坐标
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.viewDir = (o.worldPosition - _WorldSpaceCameraPos);//WorldSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 viewDir = normalize(i.viewDir);
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldPosition = normalize(i.worldPosition);
                fixed3 reflectDir = normalize(reflect(-_WorldSpaceLightPos0.xyz, worldNormal));

				fixed4 albedo = tex2D(_MainTex, i.uv) * _Color;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.rgb;
                UNITY_LIGHT_ATTENUATION(atten, i, worldPosition);

				half nDotL = dot(worldNormal, _WorldSpaceLightPos0.xyz);
                nDotL = nDotL * 0.5 + 0.5;  //half Lambert
                //albedo.rgb = albedo.rgb * _LightColor0.rgb * nDotL;
                half3 h = normalize((_WorldSpaceLightPos0.xyz + viewDir)*0.5);
                half nDotH = max(0,dot(worldNormal, h) );

                half nDotV = dot(worldNormal, viewDir);
                half RDotV = dot(reflectDir, viewDir);

                half rim = 1 - dot(worldNormal, viewDir);
                float spec = pow(saturate(RDotV),  _Glossiness);
                fixed4 col = fixed4(1,1,1,1);
                col.rgb = albedo.rgb * nDotL;
                col.rgb += _SpecalColor.rgb * spec * albedo.a;
                col.rgb += _RimColor.rgb * step(1,pow(rim, _RimPower));
                col.rgb += ambient *atten ;
                col.a = albedo.a * min(1,max(0.9,(1 - worldPosition.y+0.5)));
                return col;
            }
            ENDCG
        }
    }
}
