Shader "QING/BorderLightShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 内边缘光的颜色
        _InSideRimColor ("InSide Rim Color", Color) = (1, 1, 1, 1)
        // 内边缘光的强度
        _InSideRimPower ("InSide Rim Power", Range(0, 5)) = 0
        _InSideRimForce ("InSide Rim Force", Range(0, 10)) = 0

        _OutSideRimColor ("OutSide Rim Color", Color) = (1, 1, 1, 1)
        _OutSideRimForce ("OutSide Rim Force", Range(0, 10)) = 0
        _OutSideRimDistance ("OutSide Rime Distance", float) = 0
        _OutSideRimPower ("OutSide Rim Power", Range(0, 5)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "LightweightForward"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
               // float3 normal: TEXCOORD1;
                //float fresnel: TEXCOORD2;
                float4 vertex : SV_POSITION;
               // float4 vertexWorld: TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _InSideRimColor;
            float _InSideRimForce;
            float _InSideRimPower;

            v2f vert (appdata v)
            {
                v2f o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.normal = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz);
                //o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.vertexWorld.xyz);
               // half NdotV = max(0, dot(i.normal, worldViewDir));
               // NdotV = 1.0 - NdotV;
              //  float fresnel = pow(NdotV, _InSideRimPower) * _InSideRimForce;
              //  float3 Emissive = _InSideRimColor.rgb * fresnel;
              //  fixed4 col = tex2D(_MainTex, i.uv);
              //  return col + float4(Emissive, 1);
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMode" = "UniversalForward"}
            Cull Front
           // Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal: TEXCOORD1;
                float4 vertex : SV_POSITION;
                float4 vertexWorld: TEXCOORD2;
            };
            float4 _OutSideRimColor;
            float _OutSideRimDistance;
            float _OutSideRimForce;
            float _OutSideRimPower;

            v2f vert (appdata v)
            {
                v2f o;
                // 放大模型-基于法线方向
                v.vertex.xyz += normalize(v.normal) * _OutSideRimDistance;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 转换到世界坐标
                o.normal = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz);
                o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 从摄像机指向模型点的向量
                float3 worldViewDir = normalize(i.vertexWorld.xyz - _WorldSpaceCameraPos.xyz);
                // 发线与这个向量点乘，1表示同向， 0表示垂直， -1表示反向
                half NdotV = dot(i.normal, worldViewDir);
                float fresnel = pow(saturate(NdotV), _OutSideRimPower) * _OutSideRimForce;
                return fixed4(_OutSideRimColor.rgb , fresnel);
            }
            ENDCG
        }
    }
}
