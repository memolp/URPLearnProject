Shader "QING/Test2"
{
    Properties
    {
        _NoiseTex ("Noise Texture", 2D) = "white" {}
    }
    SubShader
    {
        // Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        // Cull Off
        // Blend SrcAlpha OneMinusSrcAlpha
        // LOD 100

        Tags { "RenderType"="Opaque"}
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldPos: TEXCOORD1;
                float4 screenPos: TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;

            sampler2D _CameraDepthTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                // 世界坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                // 屏幕坐标 注意这里是裁剪过的
                o.screenPos = ComputeScreenPos(o.vertex); 
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos));
                depth = LinearEyeDepth(depth);
                float3 worldSpaceCoords = ((_WorldSpaceCameraPos - i.worldPos) / i.screenPos.w) * depth - _WorldSpaceCameraPos;
                return float4(frac(worldSpaceCoords), 1.0);
            }
            ENDCG
        }
    }
}
