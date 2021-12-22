Shader "QING/Test" { 
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Texture", 2D) = "white" {}
        _FurColor ("Fur Color", Color) = (1, 1,1,1)
        _ExtrusionFactor("Extrusion factor", float)=0
        _Density("Density", Range(0, 200)) = 0.1
        _FinLength("FinLength", Range(0, 10)) = 0.1
        _FinJointNum("FinJointNum",Range(0, 100)) = 0.1
        _WindFreq ("WindFreq", Vector) = (1, 1,1,1)
        _WindMove ("WindMove", Vector) = (1, 1,1,1)
        _BaseMove ("BaseMove", Vector) = (1, 1,1,1)
        _FaceViewProdThresh("FaceViewProdThresh", Range(0, 10)) = 0.1
        _RandomDirection("RandomDirection", Range(0, 10)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2g
            {
                float4 vertex: SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float4 _MainTex_ST;
            float _ExtrusionFactor;
            float _Density;
            float _FinLength;
            float _FinJointNum;
            float4 _WindFreq;
            float4 _WindMove;
            float4 _BaseMove;
            float _FaceViewProdThresh;
            float _RandomDirection;
            float4 _FurColor;

            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.uv = v.uv;
                o.normal = v.normal;
                return o;
            }

            inline float rand(float2 seed)
            {
                return frac(sin(dot(seed.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            inline float3 rand3(float2 seed)
            {
                return 2.0 * (float3(rand(seed * 1), rand(seed * 2), rand(seed * 3)) - 0.5);
            }
            
            void AppendFinVertex(inout TriangleStream<g2f> stream, float2 uv, float3 posOS)
            {
                g2f output = (g2f)0;
                output.vertex = UnityObjectToClipPos(posOS);
                output.uv = uv;
                stream.Append(output);
            }

            void AppendFinVertices(inout TriangleStream<g2f> stream,v2g input0,v2g input1,v2g input2,float3 normalOS)
            {
                float3 posOS0 = input0.vertex.xyz;
                float3 lineOS01 = input1.vertex.xyz - posOS0;
                float3 lineOS02 = input2.vertex.xyz - posOS0;
                float3 posOS3 = posOS0 + (lineOS01 + lineOS02) / 2;

                float2 uv0 = TRANSFORM_TEX(input0.uv, _MainTex);
                float2 uv12 = (TRANSFORM_TEX(input1.uv, _MainTex) + TRANSFORM_TEX(input2.uv, _MainTex)) / 2;
                float uvOffset = length(uv0);
                float uvXScale = length(uv0 - uv12) * _Density;

               AppendFinVertex(stream, float2(uvOffset, 0.0) , posOS0); //float2(uvOffset, 0.0)
                AppendFinVertex(stream, float2(uvOffset + uvXScale, 0.0), posOS3); // float2(uvOffset + uvXScale, 0.0)
                // AppendFinVertex(stream, TRANSFORM_TEX(input0.uv, _MainTex), input0.vertex.xyz);
                // AppendFinVertex(stream, TRANSFORM_TEX(input1.uv, _MainTex), input1.vertex.xyz);
                // AppendFinVertex(stream, TRANSFORM_TEX(input2.uv, _MainTex), input2.vertex.xyz);


                float3 normalWS = UnityObjectToWorldNormal(normalOS);
                float3 posWS = mul(unity_ObjectToWorld, posOS0);;
                float finStep = _FinLength / _FinJointNum;
                float3 windAngle = _Time.w * _WindFreq.xyz;
                float3 windMoveWS = _WindMove.xyz * sin(windAngle + posWS * _WindMove.w);
                float3 baseMoveWS = _BaseMove.xyz;

                [loop] for (int i = 1; i <= _FinJointNum; ++i)
                {
                    float finFactor = (float)i / _FinJointNum;
                    float moveFactor = pow(abs(finFactor), _BaseMove.w);
                    float3 moveWS = normalize(normalWS + (baseMoveWS + windMoveWS) * moveFactor) * finStep;
                    float3 moveOS = mul(unity_ObjectToWorld, moveWS);
                    posOS0 += moveOS;
                    posOS3 += moveOS;
                    AppendFinVertex(stream, float2(uvOffset, finFactor), posOS0);
                    AppendFinVertex(stream, float2(uvOffset + uvXScale, finFactor), posOS3);
                }
                stream.RestartStrip();
            }

            [maxvertexcount(75)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> stream)
            {
            //#ifdef DRAW_ORIG_POLYGON
                for (int i = 0; i < 3; ++i)
                {
                    g2f output = (g2f)0; 
                    output.vertex = UnityObjectToClipPos(input[i].vertex);
                    output.uv = TRANSFORM_TEX(input[i].uv, _MainTex);
                    stream.Append(output);
                }
                stream.RestartStrip();
           // #endif
                
                float3 lineOS01 = (input[1].vertex - input[0].vertex).xyz;
                float3 lineOS02 = (input[2].vertex - input[0].vertex).xyz;
                float3 normalOS = normalize(cross(lineOS01, lineOS02));
                float3 centerOS = (input[0].vertex + input[1].vertex + input[2].vertex).xyz / 3;
                float3 viewDirOS = ObjSpaceViewDir(float4(centerOS, 1)).xyz;
                float eyeDotN = dot(viewDirOS, normalOS);
                if (abs(eyeDotN) > _FaceViewProdThresh) return;
                // normalOS *= min(_FaceViewProdThresh / pow(eyeDotN, 2), 1.0);

                normalOS += rand3(input[0].uv) * _RandomDirection;
                normalOS = normalize(normalOS);

                AppendFinVertices(stream, input[0], input[1], input[2], normalOS);

                AppendFinVertices(stream, input[2], input[0], input[1], normalOS);
                AppendFinVertices(stream, input[1], input[2], input[0], normalOS);
            }


            fixed4 frag (g2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 col1 = tex2D(_NoiseTex, i.uv);
                if(col.a < 0.5)
                    discard;
               // fixed3 finalColor = lerp(_FurColor.rgb, fixed3(1.0,1.0,1.0), col.a);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return fixed4(_FurColor.rgb * col1.r, 1.0) ;
            }
            ENDCG
        }
    }
} 