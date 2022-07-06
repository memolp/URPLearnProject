Shader "QING/Cartoon3"
{
    Properties
    {
        [Header(Main)]
        _Color          ("Color", Color) = (1, 1, 1, 1)
        _MainTex        ("Texture", 2D) = "white" {}
        _NormalTex      ("Normal", 2D) = "bump" {}
        [HDR]_AmbientColor   ("Ambient Color", Color) = (0.4,0.4,0.4,1)

        [Header(Specular)]
        [HDR]_SpecularColor  ("Color", Color) = (0.9, 0.9, 0.9, 1)  //镜面反射
        _Glossiness     ("Glossiness", float) = 32

        [Header(Rim)]
        [HDR]_RimColor       ("Color", Color) = (1, 1, 1, 1)  // 轮廓
        _RimPower       ("Power", Range(0,1)) = 0.1
        _RimAmount      ("Amount", Range(0,1)) = 0.716

    }
    SubShader
    {
        Tags {"RenderType" = "Opaque"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #define NORMAL_TEX

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

                float3 viewDir:TEXCOORD2;
                float3 lightDir:TEXCOORD3;
                float3 normal:TEXCOORD4;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
          
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                #ifdef NORMAL_TEX
                // 切线空间光照和视口方向
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
                o.normal = mul(rotation, v.normal);
                #else
                o.lightDir = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                #endif
              
                return o;
            }

            sampler2D _NormalTex;
            float4 _Color;
            float4 _AmbientColor;
            float _Glossiness;
            float4 _SpecularColor;
            float _RimPower;
            float4 _RimColor;
            fixed _RimAmount;
            float _NormalScale;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 albedo = tex2D(_MainTex, i.uv) * _Color;
                // return albedo;
                #ifdef NORMAL_TEX
                // 这里融合法线，否则锯齿很大
                float3 t_normal = normalize(BlendNormals(i.normal, UnpackNormal(tex2D(_NormalTex, i.uv))));
                float3 t_light  = normalize(i.lightDir);
                float3 t_view   = normalize(i.viewDir);
                float3 t_half   = normalize(t_light + t_view);
                #else
                float3 t_normal = normalize(i.lightDir);
                float3 t_light  = _WorldSpaceLightPos0;
                float3 t_view   = normalize(i.viewDir);
                float3 t_half   = normalize(t_light + t_view);
                #endif

                float NdotL = dot(t_normal, t_light) ;
                float lightIntensity = smoothstep(0, 0.1, NdotL);
                //float3 diffuse = lightIntensity * _LightColor0;
                float3 diffuse = lightIntensity * _LightColor0 * albedo;
                // return diffuse + _AmbientColor;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                float NdotH = saturate(dot(t_normal, t_half));
                // fixed3 rdir = normalize(reflect(t_light, t_normal));
                // float NdotH = saturate(dot(rdir, t_view));
                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                float specularIntensitySmooth  = smoothstep(0.0, 0.8, specularIntensity);
                float3 specular = _SpecularColor * specularIntensitySmooth;
                // return specular;

                float rimDot = 1 - dot(t_view, t_normal);
                float rimInstensity = rimDot * pow(saturate(NdotL), _RimPower);
                rimInstensity = smoothstep(_RimAmount-0.01, _RimAmount +0.01, rimInstensity);
                float3 rim = _RimColor * rimInstensity ;
                // return rim;
                return fixed4(diffuse + specular + ambient + rim, 1.0);
                //return albedo * (_AmbientColor + diffuse + specular + rim)*0.9;
            }
            ENDCG
        }
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
			#pragma fragment frag

            struct Attributes
            {
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
            };
 
            struct Varyings
            {
                float4 posCS        : SV_POSITION;
            };

            float3 _LightDirection;

            Varyings vert(Attributes IN)
			{
				    Varyings OUT = (Varyings)0;
                    VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.vertex.xyz);
                    float3 posWS = vertexInput.positionWS;

                    VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normal);
                    float3 normalWS = normalInput.normalWS;

                    // Shadow biased ClipSpace position
                    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(posWS, normalWS, _LightDirection));

                    #if UNITY_REVERSED_Z
                        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                    #else
                        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                    #endif

                    OUT.posCS = positionCS;

                    return OUT;
			}
 
            float4 frag (Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
