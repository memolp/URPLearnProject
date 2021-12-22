Shader "QING/HairShader"
{
    Properties
    {
        _HairTex("Texture", 2D) = "white" {}
        _SpecularShift("Hair Shifted Texture", 2D) = "white" {}

        _DiffuseColor("DiffuseColor", Color) = (0.0, 0.0, 0.0, 0.0)

        _PrimaryColor("Specular1Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _PrimaryShift("PrimaryShift", Range(-4, 4)) = 0.0
        _SecondaryColor("Specular2Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _SecondaryShift("SecondaryShift", Range(-4, 4)) = 0.5
        
        _specPower("SpecularPower", Range(0, 50)) = 20
        _SpecularWidth("SpecularWidth", Range(0, 1)) = 0.5
        _SpecularScale("SpecularScale", Range(0, 1)) = 0.3
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }

        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 tangent : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 binormal: TEXCOORD3;
                float3 pos : TEXCOORD4;
                
                UNITY_FOG_COORDS(1)
            };

            sampler2D _HairTex;
            float4 _HairTex_ST;
            sampler2D _SpecularShift;
            float4 _SpecularShift_ST;

            float4 _DiffuseColor;
            float4 _PrimaryColor;
            float _PrimaryShift;
            float4 _SecondaryColor;
            float _SecondaryShift;

            float _specPower;
            float _SpecularWidth;
            float _SpecularScale;

            v2f vert (appdata v)
            {
                v2f o;
                
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _HairTex);

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldDir(v.tangent);
                o.binormal = cross(v.normal, v.tangent) * v.tangent.w * unity_WorldTransformParams.w;

                o.pos = mul(unity_ObjectToWorld, v.vertex);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed3 shiftTangent(fixed3 T, fixed3 N, fixed shift)
            {
                return normalize(T + shift * N);
            }

            fixed hairStrand(fixed3 T, fixed3 V, fixed3 L, fixed specPower)
            {
                fixed3 H = normalize(V + L);

                fixed HdotT = dot(T, H);
                fixed sinTH = sqrt(1 - HdotT * HdotT);
                fixed dirAtten = smoothstep(-_SpecularWidth, 0, HdotT);
                
                return dirAtten * saturate(pow(sinTH, specPower)) * _SpecularScale;
            }

            fixed4 getAmbientAndDiffuse(fixed4 lightColor0, fixed4 diffuseColor, fixed3 N, fixed3 L, fixed2 uv)
            {
                return (lightColor0 * diffuseColor * saturate(dot(N, L)) + fixed4(0.2, 0.2, 0.2, 1.0)) 
                          * tex2D(_HairTex, uv);
            }

            fixed4 getSpecular(fixed4 lightColor0, 
                               fixed4 primaryColor, fixed primaryShift,
                               fixed4 secondaryColor, fixed secondaryShift,
                               fixed3 N, fixed3 T, fixed3 V, fixed3 L, fixed specPower, fixed2 uv)
            {
                float shiftTex = tex2D(_SpecularShift, uv) - 0.5;

                fixed3 t1 = shiftTangent(T, N, primaryShift + shiftTex);
                fixed3 t2 = shiftTangent(T, N, secondaryShift + shiftTex);

                fixed4 specular = fixed4(0.0, 0.0, 0.0, 0.0);
                specular += primaryColor * hairStrand(t1, V, L, specPower) * _SpecularScale;;
                specular += secondaryColor * hairStrand(t2, V, L, specPower) * _SpecularScale;

                return specular;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 N = normalize(i.normal);
                fixed3 T = normalize(i.tangent);
                fixed3 B = normalize(i.binormal);
                fixed3 V = normalize(UnityWorldSpaceViewDir(i.pos));
                fixed3 L = normalize(UnityWorldSpaceLightDir(i.pos));
                fixed3 H = normalize(L + V);

                fixed4 ambientdiffuse = getAmbientAndDiffuse(_LightColor0, _DiffuseColor, N, L, i.uv);
                fixed4 specular = getSpecular(_LightColor0, _PrimaryColor, _PrimaryShift, _SecondaryColor, _SecondaryShift, N, B, V, L, _specPower, i.uv);
                
                fixed4 col = (ambientdiffuse + specular);
                col.a = 1.0f;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}