Shader "QING/DissolveShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DissolveMap ("DissolveMap", 2D) = "white" {}
        _DissolveColor ("Dissolve Color", Color) = (0,0,0,0)
        _DissolveEdgeColor ("Dissolve Edge Color", Color) = (1, 1, 1, 1)
        _DissolveThreshold ("Dissolve Threshold", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
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
                //float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _DissolveMap;
            float4 _MainTex_ST;
            float4 _DissolveColor;
            float4 _DissolveEdgeColor;
            float _DissolveThreshold;

            v2f vert (appdata v)
            {
                v2f o;
                // 燃烧到一定程度就像烟尘一样飘散
                // 带法线的-用模型
                //v.vertex.xyz += v.normal * saturate(_DissolveThreshold - 0.8) * float3(0,1,0);  
                // 不带法线的，2D
                v.vertex.xyz += saturate(_DissolveThreshold - 0.37) * float3(0.1,2,0);  
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 dissolve_col = tex2D(_DissolveMap, i.uv);
                if(dissolve_col.r < _DissolveThreshold)
                {
                    discard;
                }
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // 当前_DissolveThreshold 基于r的百分比,会无限接近并超过r的值，也就是百分比越来越大。
                float percent_of_r = _DissolveThreshold / dissolve_col.r;
                // 越接近100%的值将越先被舍弃，因此属于边界。
                float lerpEdge = saturate(sign(percent_of_r - 0.95));
                // lerpEdge为1使用_DissolveEdgeColor的颜色，为0使用_DissolveColor的颜色
                fixed3 edgeColor = lerp(_DissolveColor.rgb, _DissolveEdgeColor.rgb, lerpEdge);
                // 还没有接近100%的属于过渡区域，可以与原来的颜色插值
                float lerpout = saturate(sign(percent_of_r - 0.7));
                // 如果为1说明需要用edgeColor，否则用col
                fixed3 lout = lerp(col.rgb, edgeColor, lerpout);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return float4(lout, col.a);
            }
            ENDCG
        }
    }
}
