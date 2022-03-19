Shader "QING/LightLine"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LineTex ("Line Tex", 2D) = "white" {}
        _LightPos("Light Position", Vector) = (1, 1, 1, 1)
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
            float4 _LightPos;
            sampler2D _LineTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed2 uv = i.uv - 0.5;
                //half dis = length(uv.xy) / _LightPos.w ;
                // 这里是要产生一个uv的x坐标
                half theta = atan(uv.y/uv.x)*_LightPos.x;
                //theta = abs(theta);
                fixed2 uv2 = fixed2(theta, _LightPos.y);
                fixed dl = length(uv.xy);
                // 采样贴图，由于uv.x 会被重新映射，实现射线
                fixed r = tex2D(_LineTex, uv2).r;
                fixed v = clamp(sin(_Time.y) + 0.2, 0.1, 0.6);
                // smoothstep用于取区间的内容
                col.rgb = col.rgb + fixed3(1,1,1)*smoothstep(0.8, 1, r) * (v-dl);
                //fixed3 lightCol = _LightPos.z * fixed3(1,1,1) * tex2D(_LineTex, uv2).r * (_LightPos.w-dl);
                //col.r = saturate(tex2D(_LineTex, uv2).r * (_LightPos.w-dl)) * _LightPos.z;
               // col.r = min(0.2, 1.0- dis) * abs(theta);
                //col.g = col.b = 0;
                //col.rgb = col.rgb + lightCol;// lerp(lightCol, col, dl);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
