Shader "QING/NoiseEffect01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseOffset("Noise Offset", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True"}
        LOD 100
        Cull Off
        ZWrite Off
        ZTest Always
        
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
                float2 uv:TEXCOORD0;
                float4 vertex: SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float _NoiseOffset;

            fixed4 frag(v2f i):SV_Target
            {
                float2 uv = i.uv + _Time.x * 2;
                float2 offset = tex2D(_NoiseTex, uv).rg; // 取值范围[0,1]
                offset = (offset * 2 - 1) * _NoiseOffset; // 将范围移动到[-1, 1]
                fixed4 col = tex2D(_MainTex, i.uv + offset); // 在原uv上进行偏移
                return col;
            }
            ENDCG
        }
    }
}