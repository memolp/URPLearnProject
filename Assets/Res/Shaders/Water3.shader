Shader "QING/WaterShader3"
{
    Properties
    {
        // 水的主颜色
        _WaterTex ("Water Texture", 2D) = "white" {}
        [HDR]_WaterColor ("Water Color", Color) = (1, 1, 1, 1)
        _WaveScale ("Wave Scale", float) = 1.0
        _WaveOffset ("Wave Offset", Vector) = (0,0,0,0)
        _FresnelPow ("Fresnel Strength", float) = 1.0
        // 水波浪的扰动纹理
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _CausticTex ("Caustic", 2D) = "white" {}
        _CausticVer ("Caustics Vector", Vector) = (1, 1, 1, 1)
        [HDR]_DeepColor("Deep Color", Color) = (1,1,1,1)
        _WaterDepth ("Water Depth", float) = 1
        _WaterFalloff("Water FallOff", float) = 1
        _WaterParams("Water Params", Vector) = (1, 1, 1, 1)
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
            #include "UnityStandardUtils.cginc"
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPos:TEXCOORD2;
                float4 uv2: TEXCOORD3;
                float3 viewDir: TEXCOORD4;
                float3 lightDir: TEXCOORD5;
                float3 normalDir: TEXCOORD6;
            };

            // 可以使用 render Texture 获得真实的水底画面，这里仅简单的
            sampler2D _WaterTex;
            float4 _WaterTex_ST;

            // 水波纹的扰动纹理
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            // 水面焦散纹理
            sampler2D _CausticTex;
            float4 _CausticTex_ST;

            float4 _WaterColor;
            float _WaveScale;
            float4 _WaveOffset;
            float _FresnelPow;

            float4 _CausticVer;
            sampler2D _CameraDepthTexture;
            float4 _DeepColor;
            float  _WaterDepth;
            float _WaterFalloff;
            float4 _WaterParams;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                o.uv = TRANSFORM_TEX(v.uv, _WaterTex);
                // 波纹纹理uv
                o.uv2.xy = TRANSFORM_TEX(v.uv, _NoiseTex);
                // 焦散纹理uv
                o.uv2.zw = TRANSFORM_TEX(v.uv, _CausticTex);
                
                // 模型点屏幕空间
                o.screenPos = ComputeScreenPos(o.vertex);

                float3 world_pos = normalize(mul(unity_WorldToObject, v.vertex));
                o.lightDir = normalize(_WorldSpaceLightPos0.xyz);
                o.viewDir = normalize(_WorldSpaceCameraPos.xyz) - world_pos;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float get_depth(float4 scrPos)
            {
                float depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(scrPos)).r;
                depth = LinearEyeDepth(depth); // 视野线性深度值
                return depth;
            }

            half stepA(half y, half x)
            {
                half v = x - y;
                return saturate(v / fwidth(v));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //将Y进去分段，固定条纹
                float sinY = sin(i.uv.y * 50); // [-1, 1]
                sinY = (sinY + 1) * 0.5; // [0, 1]
                // 水波纹躁动的因子，仅仅通过sin获得只能是太规律的
                float2 noise_factor = tex2D(_NoiseTex, i.uv2.xy + _Time.y * _WaveOffset.xy).rg;
                float2 offsetX = _WaveScale * noise_factor * sinY;
               
                // 水底 +扭曲
                fixed4 abloed = tex2D(_WaterTex, i.uv + offsetX) * _WaterColor;

                // 自定义法线，这个是切线空间，其他的都需要转切线空间
                // float2 uv1 = _Time.y * _WaveOffset.xy + i.uv;
                // float2 uv2 = _Time.y * _WaveOffset.zw + i.uv;
                // float bump_scale = 2;
                // half3 wave_1 = UnpackScaleNormal(tex2D(_NoiseTex, uv1), bump_scale);
                // half3 wave_2 = UnpackScaleNormal(tex2D(_NoiseTex, uv2), bump_scale);
                // half3 wave = BlendNormals(wave_1, wave_2);

                // 漫反射 和 镜面反射
                float3 halfDir = normalize(i.lightDir + i.viewDir);
                float RDotV = dot(i.normalDir, halfDir);
                float specular_fac = saturate(pow(saturate(RDotV), _FresnelPow));
                half3 specular = _LightColor0.rgb * specular_fac;
                half3 diffuse = _LightColor0.rgb * abloed.rgb * (1 + dot(i.normalDir, i.lightDir)) / 2;

                // 水底焦散
                float2 caustic_uv = i.uv2.zw + _WaveOffset.xy  * _Time.y + offsetX;
                // 采样生成光影效果，只使用r通道  - 0.01 是因为图的r问题。
                float r = saturate(tex2D(_CausticTex, caustic_uv ).r - 0.01);
                half3 caustic_col = half3(1,1,1);
                // 水底扭曲  和 焦散 的插值
                half3 blend_col = lerp(diffuse + specular, caustic_col, r);

                // 这坨是想做水中物件周围的水花，方式是错误的，待研究。
                // #define OFF_R 1
                // float DIS_R = 0.05 + 0.5*(1 + sin(_Time.y*2)) * 0.1;
                float depth = get_depth(i.screenPos);
                // 这样转换后获得深度插值 - 这里会反过来，越小表示深度越深。
                float depthGrap = depth - i.screenPos.w;
                // 深水颜色
                float _FogThreshold = _WaterParams.x;
                float fogDiff = saturate(depthGrap / _FogThreshold);
                // 深度与水面交界处颜色
                float _InterThreshold = _WaterParams.y;
                float interDiff = saturate(depthGrap / _InterThreshold);
                blend_col = lerp(_WaterColor.rgb, blend_col, interDiff);//lerp(lerp(_WaterColor.rgb, blend_col, interDiff), _DeepColor.rgb, fogDiff);

                // 
                float _FoamThreshold = _WaterParams.z;
                float _FoamLinesSpeed = _WaterParams.w;
                float foamDiff = saturate(depthGrap / _FoamThreshold);
                // foamDiff *= (1.0 - blend_col.b);
                
              
                // 提取深度值 - 非线性
                //float depthFade = saturate(pow(depthGrap + _WaterDepth, _WaterFalloff));
                // 深度区域处理
                // half3 finalCol = lerp(_DeepColor.rgb * _LightColor0.rgb, blend_col, depthFade);

                // 水面水花移动效果
                float no = ( tex2D(_NoiseTex, i.uv2.xy + _Time.y * _WaveOffset.zw).r);
                float depthFade = step(foamDiff - (saturate(sin((foamDiff - _Time.y * _FoamLinesSpeed) * 8 * UNITY_PI)) * (1 - foamDiff)), no);
                half3 finalCol = lerp(blend_col, _DeepColor.rgb * _LightColor0.rgb, depthFade);
                
                float face = tex2D(_CausticTex, i.uv2.zw + _Time.y * _CausticVer.xy ).g;
                // 通过扰动采样来改变这个因子 (这里过滤镜面反射区域不产生水花)
                float face_factor = face * no * (1 - specular_fac) * _CausticVer.w; 
                // 同步改变参照值，这样产生一种动态变化的效果。
                float face_shold = saturate(1 - face *  no  * _CausticVer.w); 
                // 水面处理，平滑
                // half v = stepA(face_shold,face_factor);
                half v = smoothstep(face_shold - _CausticVer.z, face_shold + _CausticVer.z, face_factor);
                // half v = smoothstep(0, fwidth(face_factor), face_factor);
                finalCol.rgb = lerp(finalCol.rgb, _DeepColor.rgb* _LightColor0.rgb, v);

                 // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                return fixed4(finalCol,abloed.a);
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
