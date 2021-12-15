
Shader "QING/SnowShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SnowTex ("Snow", 2D) = "white" {}
        _SnowCount ("Snow Power", Range(0, 10)) = 1.0
        _SnowColor ("Snow Color", Color) = (1.0, 1.0, 1.0, 1.0)
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
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float2 snowUV:TEXCOORD2;
                float snow:TEXCOORD3;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _SnowTex;
            float4 _SnowTex_ST;
            float _SnowCount;
            float4 _SnowColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 法线到世界坐标
                float3 worldNormal = mul((float3x3)unity_ObjectToWorld ,v.normal );
                // 计算法线和Y的夹角
                float rim = 1-saturate(dot(float3(0,1,0),worldNormal ));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.snowUV = TRANSFORM_TEX(v.uv , _SnowTex);
                // 控制积雪的量。
                o.snow = pow(rim,_SnowCount*64);								
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // 通过采样进行插值来获得积雪效果
                fixed4 snow = tex2D(_SnowTex,i.snowUV);
                col = lerp(snow,col,saturate(i.snow));
                UNITY_APPLY_FOG(i.fogCoord, col);
                UNITY_OPAQUE_ALPHA(col.a);
                return col;
            }
            ENDCG
        }
    }
}
