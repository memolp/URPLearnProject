Shader "QING/TwoSidedDissolve"
{
    Properties
    {
        _DissolveGuide("Dissolve guide", 2D) = "white"  {}
        _FrontColor("Front color", color) = (1,1,1,1)
        _BackColor("Back color", color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
 
        Pass
        {
            Tags { "LightMode" = "LightweightForward"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
 
            #include "UnityCG.cginc"
 
            struct appdata
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };
 
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };
 
            sampler2D _DissolveGuide;
            float4 _DissolveGuide_ST;
 
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _DissolveGuide);
                o.color = v.color;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
 
            fixed4 _FrontColor;
 
            fixed4 frag (v2f i) : SV_Target
            {
                clip(tex2D(_DissolveGuide, i.uv).x - i.color.a);
                fixed4 col = _FrontColor;               
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
        Pass
        {
            Tags { "LightMode" = "UniversalForward"}
            Cull front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
 
            #include "UnityCG.cginc"
 
            struct appdata
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };
 
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };
 
            sampler2D _DissolveGuide;
            float4 _DissolveGuide_ST;
 
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _DissolveGuide);
                o.color = v.color;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
 
            fixed4 _BackColor;
 
            fixed4 frag (v2f i) : SV_Target
            {
                clip(tex2D(_DissolveGuide, i.uv).x - i.color.a);
                fixed4 col = _BackColor;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
           
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
