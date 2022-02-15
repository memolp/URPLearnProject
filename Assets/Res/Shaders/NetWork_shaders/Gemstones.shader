Shader "Toon/Gemstones"
{
    // //https://www.patreon.com/posts/29753575
    // https://pastebin.com/nXGLJLhS
    Properties
    {
        [Header(Main)]
        _ToonRamp("Toonramp Color", Color) = (0,0,0,1)
        _MainTex("Main Texture (RGB)", 2D) = "white" {}
 
        [Header(Parallax)]
        _Parallax("Parallax", Range(0,0.5)) = 0.1
        _HeightMap("Height Map", 2D) = "white" {}
        _Normal("Normal Map", 2D) = "bump" {}
 
        [Header(Texture)]       
        _Tint("Texture Tint", Color) = (1,1,0,1)
        _ColorTop("Top Col", Color) = (0,1,1,1)
        _BottomCol("Bottom Col", Color) = (0,1,0,1)
        _Offset("Gradient Offset", Range(-1,1)) = 0.1
        _Scale("Main Texture Scale", Range(0,10)) = 1   
        _Brightness("Texture Brigthness", Range(0,5)) = 1
        
        [Header(Spec and Rim)]
        [Toggle(COLORSPEC)] _COLORSPEC("Colored Specular?", Float) = 0
        _SpecSize("Specular Size", Range(0.2,0.5)) = 0.47
        _RimPower("Rimpower", Range(0,20)) = 0.47
        _SoftRimColor("SoftRim Color", Color) = (0,0,0,1)
        _HardRimColor("HardRim Color", Color) = (0,0,0,1)
        _Brightness2("Colored Spec Brightness", Range(0,30)) = 1
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 200
          CGPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
#pragma shader_feature COLORSPEC
#pragma surface surf ToonRamp fullforwardshadows vertex:vert
#pragma target 3.5
 
        float4 _ToonRamp;
 
        // custom lighting function that uses a texture ramp based
        // on angle between light direction and normal
    #pragma lighting ToonRamp exclude_path:prepass
        inline half4 LightingToonRamp(SurfaceOutput s, half3 lightDir, half atten)
        {
    #ifndef USING_DIRECTIONAL_LIGHT
            lightDir = normalize(lightDir);
    #endif
            float d = dot(s.Normal, lightDir);
            float dChange = fwidth(d);
            float3 lightIntensity = smoothstep(0 , dChange + 0.05, d) + (_ToonRamp);
 
            half4 c;
            c.rgb = s.Albedo * _LightColor0.rgb * (lightIntensity) * (atten * 2);       
            c.a = s.Alpha; 
            return c;
        }
 
            sampler2D  _MainTex,_HeightMap, _Normal;
            struct Input
            {
                float2 uv_MainTex;
                float2 uv_Normal;
                float3 objPos;
                float3 lightDir;
                float3 viewDir2;// something weird happens to viewdir when using parallax, so it's gettin recalculated
                float3 vertexNormal;
                float3 viewDir;
 
            };
            float _RimPower;
            float4 _SoftRimColor, _HardRimColor;
            float _Offset, _Brightness2;
            fixed4  _ColorTop, _BottomCol, _Tint;
            float _SpecSize,  _Scale, _Parallax, _Brightness;
 
            void vert(inout appdata_full v, out Input o) {
                UNITY_INITIALIZE_OUTPUT(Input, o);
                o.objPos = v.vertex;
                o.lightDir = WorldSpaceLightDir(v.vertex); // get the worldspace lighting direction
                o.vertexNormal = mul(unity_ObjectToWorld, v.normal);
                o.viewDir2 = WorldSpaceViewDir(v.vertex);
            }
 
            void surf(Input IN, inout SurfaceOutput o)
            {
 
                //parallax
                float heightTex = tex2D(_HeightMap, IN.uv_MainTex).r;
                float2 parallaxOffset = ParallaxOffset(heightTex, _Parallax, IN.viewDir);
 
                // specular
                half s = dot((IN.vertexNormal), normalize(IN.lightDir + IN.viewDir2))*0.5;
                s = step(_SpecSize, s);
 
                // normals
                o.Normal = UnpackNormal(tex2D(_Normal, IN.uv_Normal + parallaxOffset));
 
                // tex
                float4 c = tex2D(_MainTex, (float2(IN.uv_MainTex.xy) - parallaxOffset * _Scale));
 
                // add extra tint
                c *= _Tint;
                c *= _Brightness;
            
                // rim lighting
                float Rim = 1.0 - saturate(dot(normalize(o.Normal), normalize(IN.viewDir)));// calculate a soft fresnel based on the view direction and the normals of the object
                float softRim = pow(Rim, _RimPower);
                float hardRim = round(softRim);
            
                float4 softRimColored = softRim * _SoftRimColor;
                float4 hardRimColored = hardRim * _HardRimColor;
 
                // lerp colors
                float4 colors = lerp(_BottomCol, _ColorTop, saturate(IN.objPos.y+ _Offset)) + c;
                
                // specular and rim emmision
#if COLORSPEC
                o.Emission = ((s * colors) * _Brightness2) + softRimColored + hardRimColored;
#else
                o.Emission = s  + softRimColored + hardRimColored;
#endif
                o.Albedo = colors;
            }
            ENDCG
        }
            FallBack "Diffuse"
}