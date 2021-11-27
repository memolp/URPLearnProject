Shader "QING/WaveShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Direction("Direction", Vector) = (0, 0, 0, 0)
		_TimeScale("TimeScale", float) = 1
		_TimeDelay("TimeDelay", float) = 1
    }
    SubShader
    {
        Tags { 
            "QUEUE"="Transparent"       
            "IGNOREPROJECTOR"="true" 
            "RenderType"="Transparent" 
            "PreviewType"="Plane" 
            "CanUseSpriteAtlas"="true"
        }

        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

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
            float4 _Direction;
            float _TimeScale;
            float _TimeDelay;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                // _TimeScale 大1，加快上下浮动， 小于1 减慢上限浮动
                // _TimeDelay 偏移的情况，也就是曲线刚开始的起点位置 sin(0) 默认是0， sin(0+1) 就产生了向左偏移 
                float time = (_Time.y + _TimeDelay) * _TimeScale;
                // 世界坐标
                //float4 world_pos = mul(unity_ObjectToWorld, v.vertex);
                // 水波纹效果
                // float val = sin(world_pos.y);
                // _Direction.x = val * _Direction.x;
                // 上下浮动
                v.vertex.xyz += (sin(time) * cos(time *2 / 3) + 1) * _Direction.xyz;
                // 默认
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
