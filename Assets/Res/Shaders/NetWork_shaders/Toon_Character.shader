Shader "Toon/Character" 
{
    // https://www.patreon.com/posts/31534289
    // https://pastebin.com/1n5J6wxr
    Properties{
        _Color("Main Color", Color) = (0.5,0.5,0.5,1)
        _MainTex("Base (RGB)", 2D) = "white" {}
        _Offset("Toon Ramp Blur",  Range(0, 1)) = 0 
        _Mask("R = Emis, G = Spec", 2D) = "black" {}
        _SpecTint("Spec Tint", Color) = (1,1,1,1)
        _HitTint("Hit Tint", Color) = (1,1,1,1)
        [PerRendererData] _Hit("Hit", Range(0, 1)) = 0 // hide in inspector
 
    }
 
        SubShader{
            Tags{ "RenderType" = "Opaque" }
            LOD 200
            Cull Off
 
            CGPROGRAM
 
        #pragma surface surf ToonRamp fullforwardshadows addshadow
 
            float _Offset;
            
            // custom lighting function based
            // on angle between light direction and normal
        #pragma lighting ToonRamp //exclude_path:prepass
            inline half4 LightingToonRamp(SurfaceOutput s, half3 lightDir, half atten)
            {
        #ifndef USING_DIRECTIONAL_LIGHT
                lightDir = normalize(lightDir);
        #endif
                float d = dot(s.Normal, lightDir);
                float3 lightIntensity = smoothstep(0 , fwidth(d) + _Offset , d);
 
                half4 c;
                c.rgb = s.Albedo * _LightColor0.rgb * lightIntensity * (atten * 2);
                c.a = s.Alpha; 
                return c;
            }
 
 
            sampler2D _MainTex;
            float4 _Color, _HitTint;
            sampler2D _Mask;
            float4 _SpecTint;
 
            struct Input {
                float2 uv_MainTex : TEXCOORD0;
                float3 viewDir;
            };
 
            // property blocks for hit effects
            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float, _Hit)
            UNITY_INSTANCING_BUFFER_END(Props)
 
 
            void surf(Input IN, inout SurfaceOutput o) {
                // main texture
                half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
 
                // effects mask
                half4 e = tex2D(_Mask, IN.uv_MainTex);
 
                // spec
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float spec = dot(IN.viewDir, o.Normal);// specular based on view and light direction
                float cutOff = step(saturate(spec), 0.8); // cutoff for where base color is
                float3 specularMain = c.rgb * (1 - cutOff) * e.g * _SpecTint * 4;// inverted base cutoff times specular color
 
                // highlight 
                float highlight = saturate(dot(normalize(lightDir + (IN.viewDir * 0.5)), o.Normal)); // highlight based on light direction
                float3 highlightMain = (step(0.9,highlight) * c.rgb *_SpecTint * 2) * e.g; //glowing highlight
 
                // rim
                half rim = 1 - saturate(dot(normalize(IN.viewDir), o.Normal));// standard rim calculation  
 
                // emissive glow based on red channel
                o.Emission = e.r * (c.rgb * 2);
 
                // add a glow via the specular green channel as well
                o.Emission += (pow(rim, 7) * e.g * c.rgb* _SpecTint * 5);
                // hit effect, power 2 is how much model is covered, higher number is less coverage
                o.Emission += (pow(rim, 2) * (UNITY_ACCESS_INSTANCED_PROP(Props, _Hit) * 2 * _HitTint));
                
                // glow of dissolve
                o.Emission += highlightMain;
 
                // final color
                o.Albedo = c.rgb + specularMain;
 
                // main rim
                // rim on the lit side
                float DotLight = dot(lightDir, o.Normal);
                // blend with normal rim
                float rimIntensity = rim * pow(DotLight, 0.1);
                // cutoff
                rimIntensity = smoothstep(0.7,fwidth(rimIntensity) + 0.7, rimIntensity);
 
                // add strong rim 
                o.Albedo += (rimIntensity * 2 * c.rgb);
 
        
            }
            ENDCG
 
        }
 
            Fallback "Diffuse"
}