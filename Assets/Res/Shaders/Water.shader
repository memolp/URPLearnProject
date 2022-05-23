Shader "QING/WaterShader"
{
    Properties
    {
        _WaterNormal ("Texture", 2D) = "white" {}
        _NormalScale ("Normal Scale", float) = 1

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
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent: TANGENT;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 lightDir:TEXCOORD2;
                float3 viewDir:TEXCOORD3;
                float4 screenPos:TEXCOORD4;
            };

            sampler2D _WaterNormal;
            float4 _WaterNormal_ST;
            float _NormalScale;
            sampler2D _CameraDepthTexture;
            float _WaterDepth;
            float _WaterFallOff;
            float4 _DeepColor;
            float4 _ShadowColor;
            float4 _Specular;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _WaterNormal); // 一张水面法线图
                // 模型顶点在屏幕中的坐标（是齐次坐标）
                o.screenPos = ComputeScreenPos(o.vertex);
                // 创建世界坐标到切线空间的转换矩阵rotation
                TANGENT_SPACE_ROTATION;
                // 将光从模型空间转换到切线空间
                o.lightDir = normalize(mul(rotation, ObjSpaceLightDir(v.vertex)).xyz); //ObjSpaceLightDir 是转模型空间
                // 将模型顶点到摄像机方向 转换到 切线空间
                o.viewDir = normalize(mul(rotation, ObjSpaceViewDir(v.vertex)).xyz);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 扰动采样UV
                float2 uv1 = _Time.y * float2(-0.03, 0) + i.uv;
                float2 uv2 = _Time.y * float2(0.04, 0.04) + i.uv;
                // 采样水面法线贴图，并进行凹凸缩放
                float3 noraml_1 = UnpackScaleNormal(tex2D(_WaterNormal, uv1), _NormalScale);
                float3 noraml_2 = UnpackScaleNormal(tex2D(_WaterNormal, uv2), _NormalScale);
                // 将两次的法线进行混合
                half3 blend_normal = BlendNormals(noraml_1, noraml_2);

                // 提取深度值 - 非线性
                float depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r;
                depth = LinearEyeDepth(depth); // 视野线性深度值
                float depthGrap = saturate(depth - i.screenPos.w);
                // 这样转换后获得深度插值 - 这里会反过来，越小表示深度越深。
                float depthFade = saturate(pow(depthGrap + _WaterDepth, _WaterFallOff));
                // 深度越小的地方用_DeepColor，越大的地方用_ShadiwColor;
                fixed4 color = lerp(_DeepColor, _ShadowColor, depthFade);

                // 计算光照 
                fixed3 diffuse = _LightColor0.rgb * color * ( 1 + dot(blend_normal, i.lightDir));
                float3 halfDir = normalize(i.lightDir + i.viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(blend_normal, halfDir)), _Gloss);

                return fixed4(diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
}
