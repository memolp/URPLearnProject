Shader "QING/FireShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ScrollSpeed("Animation Speed", Range(0, 2)) = 1
	
		_Color1 ("Color 1", Color) = (0, 0, 0, 1)
		_Color2 ("Color 2", Color) = (0, 0, 0, 1)
		_Color3 ("Color 3", Color) = (0, 0, 0, 1)
		
		_Edge1 ("Edge 1-2", Range(0, 1)) = 0.25
		_Edge2 ("Edge 2-3", Range(0, 1)) = 0.5
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color1;
			fixed4 _Color2;
			fixed4 _Color3;
			
			float _Edge1;
			float _Edge2;
			
			float _ScrollSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float aaStep(float compValue, float gradient)
            {
                float change = fwidth(gradient);
                //base the range of the inverse lerp on the change over two pixels
                float lowerEdge = compValue - change;
                float upperEdge = compValue + change;
                //do the inverse interpolation
                float stepped = (gradient - lowerEdge) / (upperEdge - lowerEdge);
                stepped = saturate(stepped);
                //smoothstep version here would be `smoothstep(lowerEdge, upperEdge, gradient)`
                return stepped;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float fireGradient = 1 - i.uv.y;
                fireGradient = fireGradient * fireGradient;
                //calculate fire UVs and animate them
                float2 fireUV = TRANSFORM_TEX(i.uv, _MainTex);
                fireUV.y -= _Time.y * _ScrollSpeed;
                //get the noise texture
                float fireNoise = tex2D(_MainTex, fireUV).x;
                
                //calculate whether fire is visibe at all and which colors should be shown
                float outline = aaStep(fireNoise, fireGradient);
                float edge1 = aaStep(fireNoise, fireGradient - _Edge1);
                float edge2 = aaStep(fireNoise, fireGradient - _Edge2);
                
                //define shape of fire
                fixed4 col = _Color1 * outline;
                //add other colors
                col = lerp(col, _Color2, edge1);
                col = lerp(col, _Color3, edge2);
                return col;
            }
            ENDCG
        }
    }
}
