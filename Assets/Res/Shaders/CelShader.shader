Shader "QING/CelShader"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Normal/Bump Map", 2D) = "bump" {}
		_Color ("Tint Color", Color) = (1,1,1,1)
		_Antialiasing("Band Smoothing", Float) = 5.0
		_Glossiness("Glossiness/Shininess", Float) = 400
		_Fresnel("Fresnel/Rim Amount", Range(0, 1)) = 0.5
		_OutlineSize("Outline Size", Float) = 0.01
		_OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
		_ID("Stencil ID", Int) = 1
		_LightingRamp("Lighting Ramp", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
		//Pass
		//{
        //    Tags { "LightMode"  = "LightweightForward" }
			/*Cull Front
			ZWrite OFF
			ZTest ON
			Stencil
			{
				Ref[_ID]
				Comp notequal
				Fail keep
				Pass replace
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			float _OutlineSize;
			float4 _OutlineColor;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f 
			{
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				float3 normal = normalize(v.normal) * _OutlineSize;
				float3 pos = v.vertex + normal;

				o.vertex = UnityObjectToClipPos(pos);

				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				return _OutlineColor;
			}*/

            /*//描边只用渲染背面，挤出轮廓线，所以剔除正面
            Cull Front
            //开启深度写入，防止物体交叠处的描边被后渲染的物体盖住
            ZWrite On
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _OutlineSize;
            float _Factor;
            fixed4 _OutlineColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float3 pos=normalize(v.vertex.xyz);
                float3 normal=normalize(v.normal);

                //点积为了确定顶点对于几何中心的指向，判断此处的顶点是位于模型的凹处还是凸处
                float D=dot(pos,normal);
                //校正顶点的方向值，判断是否为轮廓线
                pos*=sign(D);
                //描边的朝向插值，偏向于法线方向还是顶点方向
                pos=lerp(normal,pos,1);
                //将顶点向指定的方向挤出
                v.vertex.xyz+=pos*_OutlineSize;
                o.vertex=UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(_OutlineColor.rgb,1);
            }
            
			ENDCG*/
		//}
        Pass
        {
            Tags { "LightMode"  = "UniversalForward" }
            Stencil
            {
                Ref[_ID]
                Comp always
                Pass replace
                ZFail keep
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 worldNormal : NORMAL;
				float3 viewDir : TEXCOORD1;
                float2 uv_BumpMap: TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
			float4 _Color;
			float _Antialiasing;
			float _Glossiness;
            float _Fresnel;
		    sampler2D _LightingRamp;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv_BumpMap = TRANSFORM_TEX(v.uv, _BumpMap);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            float _OutlineSize;
            fixed4 _OutlineColor;
            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 albedo = tex2D(_MainTex, i.uv) * _Color;

				// float3 normal = normalize(i.worldNormal);
                // 如果使用法线贴图，需要全部转切线空间
                float3 normal = UnpackNormal(tex2D(_BumpMap, i.uv_BumpMap));
                normal = normal.xzy;
				float diffuse = dot(normal, _WorldSpaceLightPos0);

				// float delta = fwidth(diffuse) * _Antialiasing;
				// float diffuseSmooth = smoothstep(0, delta, diffuse);
                float3 diffuseSmooth = tex2D(_LightingRamp, float2(diffuse * 0.5 + 0.5, 0.5));

				float3 halfVec = normalize(_WorldSpaceLightPos0 + i.viewDir);
				float specular = dot(normal, halfVec);
				specular = pow(specular * diffuseSmooth, _Glossiness);

				float specularSmooth = smoothstep(0, 0.01 * _Antialiasing, specular);

				float rim = 1 - dot(normal, i.viewDir);
                rim = rim * pow(diffuse, 0.3);
                float fresnelSize = 1 - _Fresnel;

                float rimSmooth = smoothstep(fresnelSize, fresnelSize * 1.1, rim);

                float3 col = albedo * ((diffuseSmooth + specularSmooth + rimSmooth) * _LightColor0 + unity_AmbientSky);
               
                return float4(col, albedo.a);

                // 描边功能 这种不好呀。。。。。
               float edgeValue = step(0, dot(i.viewDir, normal) - _OutlineSize);
               return lerp(_OutlineColor, float4(col, albedo.a), edgeValue);
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}