Shader "Hidden/Noise Sprite Overlay"
{
    // https://www.patreon.com/posts/33606001
    // https://pastebin.com/DcX1eYsT
    Properties
    {
        [HideInInspector]_MainTex("Texture", 2D) = "white" {}
        _RenderTexture("Render Texture", 2D) = "black" {}
        _Noise("Noise", 2D) = "white" {}
        _ShadowC("ShadowColor", Color) = (0.1, 0.1, 0.1, 0.1)
        _NScale("Noise Scale", Range(0,10)) = 2
        _LightMultiplier("Light Circle Smoothness", Range(0, 5)) = 3
        _ExtraLight("Light Strength", Range(0.5, 5)) = 1
        _Cutoff("Cutoff Noise", Range(0, 1)) = 1
        _SmoothEdge("Smooth Edge", Range(0, 1)) = 0.1
        _SPeedX("Scroll Speed X", Range(-5, 5)) = 0
        _SPeedY("Scroll Speed Y", Range(-5, 5)) = -1
    }
        SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
 
 
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
 
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
 
            sampler2D _MainTex, _RenderTexture, _Noise;
            float4 _ShadowC;
            float _Cutoff, _SmoothEdge;
            float _LightMultiplier, _NScale, _ExtraLight;
            float _SPeedX, _SPeedY;
 
            fixed4 frag(v2f i) : SV_Target
            {
                // scrolling speed
            float scrollSpeedX = _Time.x * _SPeedX;
            float scrollSpeedY = _Time.y * _SPeedY;
            float2 scrolling = float2(scrollSpeedX, scrollSpeedY);
            
            // noise
            fixed4 noise = tex2D(_Noise, i.uv * _NScale + scrolling);
            fixed4 noise2 = tex2D(_Noise, i.uv * (_NScale * 2) + scrolling);
            float combNoise = (noise + noise2)* 0.5; // combine different scale noise
 
            fixed4 lights = (tex2D(_RenderTexture, i.uv) * combNoise * 2) * _LightMultiplier;// lighting layer with added noise
            lights = smoothstep(_Cutoff, _Cutoff + _SmoothEdge, lights);// create cutoff
            lights = saturate(lights); // saturate so it's not extra bright where the lights are
            fixed4 col = tex2D(_MainTex, i.uv);// normal camera view
 
            col = lerp(col * _ShadowC, col , lights * _ExtraLight);// lerp normal view multiplied by shadow color, with normal camera view over the noise lights layer
            return col;
        }
        ENDCG
    }
    }
}