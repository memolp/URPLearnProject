Shader "QING/SnowShader3" {
	Properties{
		_Color("Main Color", Color) = (0.5,0.5,0.5,1)
		_MainTex("Base (RGB)", 2D) = "white" {}
	    _Ramp("Toon Ramp (RGB)", 2D) = "gray" {}
	    _SnowRamp("Snow Toon Ramp (RGB)", 2D) = "gray" {}
	    _SnowAngle("Angle of snow buildup", Vector) = (0,1,0)
		_SnowColor("Snow Base Color", Color) = (0.5,0.5,0.5,1)
		_TColor("Snow Top Color", Color) = (0.5,0.5,0.5,1)
		_RimColor("Snow Rim Color", Color) = (0.5,0.5,0.5,1)
		_RimPower("Snow Rim Power", Range(0,4)) = 3
		_SnowSize("Snow Amount", Range(-2,2)) = 1 
		_Height("Snow Height", Range(0,0.2)) = 0.1
	}

    SubShader{
		Tags{ "RenderType" = "Opaque" }
		LOD 200
		Cull Off
        Pass{
            CGPROGRAM
         #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"
        #include "AutoLight.cginc"
        #include "Lighting.cginc"

        sampler2D _MainTex;
        sampler2D _Ramp;
        sampler2D _SnowRamp;
        float4 _MainTex_ST;
	
        float4 _Color;
        float4 _SnowColor;
        float4 _TColor;
        float4 _SnowAngle;
        float4 _RimColor;

        float _SnowSize;
        float _Height;
        float _RimPower;


        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            float3 normal:NORMAL;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float3 worldPosition:TEXCOORD2;
            float3 worldNormal:TEXCOORD3;
            float4 vertex : SV_POSITION;
        };

        v2f vert (appdata v)
        {
            v2f o;
            if(dot(v.normal, _SnowAngle.xyz) >= _SnowSize)
            {
                v.vertex.xyz += v.normal * _Height;
            }
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            // 模型顶点-世界坐标
            o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
            // 法线 - 世界坐标
            o.worldNormal = mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz;
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            float3 worldNormal = normalize(i.worldNormal);
            float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPosition));
            float3 worldPosition = normalize(i.worldPosition);
            float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPosition));
            float3 worldHalfDir = normalize(worldLightDir + worldViewDir);

            fixed4 c = tex2D(_MainTex, i.uv);
            fixed3 abledo = c.rgb * _Color.rgb;

            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * abledo;
            UNITY_LIGHT_ATTENUATION(atten, i, i.worldPosition);

            fixed diff = dot(worldNormal, worldLightDir);
            diff = (diff * 0.5 + 0.5)*atten;

            fixed3 diffuse = _LightColor0.rgb * abledo * tex2D(_Ramp, float2(diff, diff)).rgb;
            fixed spec = dot(worldNormal, worldHalfDir);
            fixed w = fwidth(spec) * 3.0;
            float _SpecularScale = 0.0;
            fixed3 _Specular = fixed3(1,1,1);
            fixed spvalue = smoothstep(-w,w,spec-(1-_SpecularScale)) * step(0.0001,_SpecularScale);
            fixed3 specular = _Specular.rgb * spvalue;
            fixed4 color = fixed4(ambient + diffuse + specular, 1.0);

            half rim = 1.0 - saturate(dot(worldViewDir, worldNormal));
            if(dot(worldNormal, _SnowAngle.xyz) >= _SnowSize)
            {
                color.rgb = _SnowColor.rgb + _RimColor.rgb * pow(rim, _RimPower);
            }

            return color;
        }

        // void disp(inout appdata_full v, out Input o)
        // {
        //     UNITY_INITIALIZE_OUTPUT(Input, o);
        //     o.lightDir = WorldSpaceLightDir(v.vertex); // light direction for snow ramp
        //     float4 snowC = mul(_SnowAngle , unity_ObjectToWorld); // snow direction convertion to worldspace
        //     if (dot(v.normal, snowC.xyz) >= _SnowSize ) {
        //         v.vertex.xyz += v.normal * _Height;// scale vertices along normal
        //     }

        // }
	    ENDCG
        }
	}
    Fallback "Diffuse"
}