Shader "QING/OldColShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                fixed3 worldVertex = normalize(mul(unity_WorldToObject, v.vertex));
                // 获取环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                // 世界空间的法线
                fixed3 worldNoraml = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                // 世界空间的光 - 这里是从顶点到光源方向的向量
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                // 法线和灯光同方向为1，相互垂直为0，相反则为-1. 或者是光和法线的夹角，小于90度为正数，大于90度为负数。
                float NdotL = dot(worldNoraml, worldLight);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(NdotL);
                // 计算光基于法线的反射光，注意光取负，变成从光源到顶点的方向，这样是正常的算反射。
                fixed3 reflectDir = normalize(reflect(-worldLight, worldNoraml))
                // 从顶点到摄像机方向的向量，也就是指向眼睛看的向量。
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz) - worldVertex;
                // 反射的光线如果和执行摄像机的向量夹角越小，说明反射到了眼睛可见。
                float RDotV = dot(reflectDir, viewDir);
                // 通过pow，光泽度来强化发射效果
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(RDotV), _Gloss);
                o.color = ambient + diffuse + specular;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               // 获取环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                // 世界空间的法线 - 这个可以在顶点中计算
                fixed3 worldNoraml = normalize(mul(i.normal, (float3x3)unity_WorldToObject));
                // 世界空间的光 - 这里是从顶点到光源方向的向量
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                // 法线和灯光同方向为1，相互垂直为0，相反则为-1. 或者是光和法线的夹角，小于90度为正数，大于90度为负数。
                float NdotL = dot(worldNoraml, worldLight);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(NdotL);
                return fixed4(ambient + diffuse, 1.0);
            }
            ENDCG
        }
    }
}
