Shader "QING/StylizedSkybox"
{
    Properties
    {
        [Header(Sky color)]
        [HDR]_ColorTop("Color top", Color) = (1,1,1,1)
        [HDR]_ColorMiddle("Color middle", Color) = (1,1,1,1)
        [HDR]_ColorBottom("Color bottom", Color) = (1,1,1,1)

        _MainTex ("Texture", 2D) = "white" {}
        _SunRadius("SunRadius", float) = 1
        _MoonRadius("MoonRadius", float) = 1
        _MoonOffset("MoonOffset", Range(-1,1)) = -1

        [Header(Clouds)]
        [HDR]_CloudsColor("Clouds color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Background" "Queue"="Background" "PreviewType"="Quad"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            fixed4 _ColorBottom;
            fixed4 _ColorMiddle;
            fixed4 _ColorTop;
            fixed4 _CloudsColor;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _SunRadius;
            float _MoonRadius;
            float _MoonOffset;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 球体UV
                /*
                获取世界位置并将其标准化。这样我们就可以确保我们正在处理一个球体，这是我们希望我们的天空盒具有的形状。
                取Y 分量的反正弦值。这将消除顶部附近的拉伸。我们仍然需要将该值除以Pi /2，因为 Arcsin(1) = Pi /2。
                计算X 和 Z 分量的反正切 2 。这将返回天空盒圆周上的角度。除以Tau（您可以使用Constant节点获取Tau的值）。
                最后，将（现在是两个）组件重新组合成一个 Vector2。这些是我们的紫外线坐标！
                */
                float2 uv = float2(atan2(i.uv.x,i.uv.z) / UNITY_TWO_PI, asin(i.uv.y) / UNITY_HALF_PI);
                float middleThreshold = smoothstep(0.0, 0.3, i.uv.y+0.5);
                float topThreshold = smoothstep(0.3, 0.5, i.uv.y+0.1);
                fixed4 col = lerp(_ColorBottom, _ColorMiddle, middleThreshold);
                col = lerp(col, _ColorTop, topThreshold);

                float cloudsThreshold = i.uv.y - 0.1;//- _CloudsThreshold;
                float cloudsTex = tex2D(_MainTex, uv * _MainTex_ST.xy + _MainTex_ST.zw + float2(0.01, 0.01) * _Time.y);
                float clouds = smoothstep(cloudsThreshold, cloudsThreshold+0.05, cloudsTex);
                col = lerp(_CloudsColor, col, clouds);
                //return col;
               //return tex2D(_MainTex, uv);
                // // 太阳
                // float sun = distance(i.uv.xyz, _WorldSpaceLightPos0);
                // float sunDisc = 1 - saturate(sun / _SunRadius);
                // sunDisc = saturate(sunDisc * 50);
                // // 月亮
                // float moon = distance(i.uv.xyz, -_WorldSpaceLightPos0);
                // float moonDisc = 1 - (moon / _MoonRadius);
                // // 月亮的 月满月亏
                // float crescentMoon = distance(float3(i.uv.x + _MoonOffset, i.uv.yz), -_WorldSpaceLightPos0);
                // float crescentMoonDisc = 1 - (crescentMoon / _MoonRadius);
                // crescentMoonDisc = saturate(crescentMoonDisc * 50);
                // moonDisc = saturate(moonDisc * 50);
                // float newMoonDisc = saturate(moonDisc - crescentMoonDisc);

                // col = col + fixed4(newMoonDisc+sunDisc, newMoonDisc+sunDisc, newMoonDisc+sunDisc, 1);
                //fixed4 col = tex2D(_MainTex, i.uv);
                //return col;
                return col;
            }
            ENDCG
        }
    }
}
