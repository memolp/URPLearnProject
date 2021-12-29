Shader "QING/WaterShader2"
{
    Properties
    {
        _ReflectiveColor ("ReflectiveColor", 2D) = "white" {}
        _BumpMap ("BumpMap", 2D) = "bump" {}
        _WaveScale ("WaveScale", Range(0, 10)) = 0.1
        _WaveOffset("WaveOffset", vector) = (0.1, 0.1, 0.1, 1)
        _FresnelPow("FresnelPow", Range(0, 2)) = 0.1
        _HorizonColor("HorizonColor", Color) = (1, 1, 1, 1)

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
                float4 tangent: TANGENT;
                float3 normal: NORMAL;
                float4 color:COLOR;
            };

            struct v2f
            {
                float2 bumpuv0 : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float2 bumpuv1:TEXCOORD2;
                float3 viewDir:TEXCOORD3;
                float4 color:COLOR;
            };

            sampler2D _ReflectiveColor;
            sampler2D _BumpMap;

            float _WaveScale;
            float _FresnelPow;
            float4 _WaveOffset;
            float4 _HorizonColor;

            v2f vert (appdata v)
            {
                v2f o;
                // 根据顶点xz 生成波纹法线采样的uv数据
                fixed4 temp;
                temp.xyzw = v.vertex.xzxz * _WaveScale / 1.0 + _WaveOffset;
                o.bumpuv0 = temp.xy;
                o.bumpuv1 = temp.wz;

                o.viewDir.xyz = ObjSpaceViewDir(v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.viewDir = normalize(i.viewDir);
                fixed3 bump1 = UnpackNormal(tex2D(_BumpMap, i.bumpuv0)).rgb;
                fixed3 bump2 = UnpackNormal(tex2D(_BumpMap, i.bumpuv1)).rgb;
                fixed3 bump = (bump1 + bump2) * 0.5;
                // 视线与法线的夹角。同向1，反向-1， 垂直0 ，然后pow放大
                fixed fresnelFac = pow(saturate(dot(i.viewDir, bump)), _FresnelPow);

                fixed4 color;
                fixed4 water = tex2D(_ReflectiveColor, float2(fresnelFac, fresnelFac));
                color.rgb = lerp(water.rgb, _HorizonColor.rgb, water.r);
                color.a = _HorizonColor.a * i.color.a;
                return color;
            }
            ENDCG
        }
    }
}
