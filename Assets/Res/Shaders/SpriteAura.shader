Shader "QING/SpriteAura"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Texture", 2D) = "white" {}
        //[Header("Noise Move Speed")]
        _SpeedX ("X Speed", float) = 0.1
        _SpeedY ("Y Speed", float) = 0.1

        _EffectSizeOffset("xy=offset, w=size", vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
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

            sampler2D _NoiseTex;

            float _SpeedY;
            float _SpeedX;
            float4 _EffectSizeOffset;

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
                
                float timeX = _Time.x * _SpeedX;
                float timeY = _Time.x * _SpeedY;
                float2 noise_uv = float2(i.uv.x * _EffectSizeOffset.z+ timeX, i.uv.y *_EffectSizeOffset.z+ timeY);
                float d = tex2D(_NoiseTex, noise_uv)*0.1;

               // return d;
               float2 scale_uv = i.uv * (1+_EffectSizeOffset.w) - _EffectSizeOffset.xy;
               float4 r = tex2D(_MainTex, float2(scale_uv.x +d, scale_uv.y+d));
            //    return r;
                r *= r.a;
                //return r + d;
                //return r;
               r *= lerp(0, 1, (i.uv.y + 21));
               r *= (1 - col.a) * fixed4(1,0,0,1);
                
               /*  float4 tinting = _Color + (c * _Multiplier);
                // add brightness
                r += (_Brightness * r.a) * tinting;
                // set effect opacity
                r = saturate(r *_Opacity);*/

               //return r;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return r + col;
            }
            ENDCG
        }
    }
}
/*
Shader "Sprite/Distort Aura" {
    Properties{
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Distort("Distort Texture", 2D) = "grey" {}
        _Color("Color", Color) = (1, 0, 1, 1)
        _Offset("Offset", Range(-4,10)) = 0
        _Multiplier("Sprite Multiplier", Range(-2,2)) = 1
        _Scale("Distort Scale", Range(0,10)) = 3.2
        _SpeedX("Speed X", Range(-10,10)) = 2
        _SpeedY("Speed Y", Range(-10,10)) = -3.2
        _EffectSize("Effect Size", Range(-0.1,0.1)) = -0.03
        _EffectOffset("Effect Offset", Range(-0.1,0.1)) = 0
        _Brightness("Brightness", Range(-10,10)) = 1.5
        _Opacity("Opacity", Range(-5,10)) =1.2
        [Toggle(ORDER)] _ORDER("Aura Behind", Float) = 1
        [Toggle(ONLY)] _ONLY("Only Aura", Float) = 0
        [Toggle(GRADIENT)] _GRADIENT("Fade To Bottom", Float) = 1
    }
        SubShader{
            Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
        }
        // stencil for (UI) Masking
        Stencil
       {
           Ref[_Stencil]
           Comp[_StencilComp]
           Pass[_StencilOp]
           ReadMask[_StencilReadMask]
           WriteMask[_StencilWriteMask]
       }
        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha
 
        Pass {
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature ORDER                
            #pragma shader_feature GRADIENT             
            #pragma shader_feature ONLY
            #include "UnityCG.cginc"
 
            sampler2D _MainTex, _Distort;
 
            struct v2f {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
            };
 
            v2f vert(appdata_base v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }
 
            float4 _Color;
            float _Offset;
            float _Brightness;
            float _EffectSize;
            float _EffectOffset;
            float _Scale;
            float _SpeedY, _SpeedX;
            float _Opacity;     
            float _Multiplier;          
 
            fixed4 frag(v2f i) : COLOR
            {
 
            half4 c = tex2D(_MainTex, i.uv);
            c *= c.a;
 
            // scale UV
            float2 scaledUV = (i.uv * (1 +_EffectSize)) - _EffectOffset;
            // UV movement
            float timeX = _Time.x * _SpeedX;
            float timeY = _Time.x * _SpeedY;
 
            //move the distort textures uv and scale them
            float d = tex2D(_Distort, float2(i.uv.x * _Scale + timeX, i.uv.y * _Scale + timeY)) * 0.1;
            // set the texture over distorted uvs
            float4 r = tex2D(_MainTex, float2(scaledUV.x +d , scaledUV.y +d));
            
            // multiply by alpha for cutoff
            r *= r.a;
 
            #if GRADIENT
            // gradient over UV vertically
            r *= lerp(0, 1, (i.uv.y + _Offset));
            #endif
            #if ORDER
            // delete original sprite's alpha to only have the outline
            r *= (1 - c.a);
            #endif
            // extra color tinting with multiplier to original sprite
            float4 tinting = _Color + (c * _Multiplier);
            // add brightness
            r += (_Brightness * r.a) * tinting;
            // set effect opacity
            r = saturate(r *_Opacity);
            #if ONLY
            return r;
            #endif
            return r + c;
        }
 
        ENDCG
    }
        }
            FallBack "Diffuse"
}
Ad
*/