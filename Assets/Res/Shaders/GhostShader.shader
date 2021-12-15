Shader "QING/Ghost"
{
    Properties
    {
        _RimColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimIntensity ("Rim Intensity", Range(0, 5)) = 1

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
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 color:TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            float4 _RimColor;
            float _RimIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                float val = 1 - saturate(dot(v.normal, viewDir));
                o.color = _RimColor * val * (1 + _RimIntensity);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.color;
            }
           
            ENDCG
        }
    }
}
