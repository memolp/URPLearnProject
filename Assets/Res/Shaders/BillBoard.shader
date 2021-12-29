// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: commented out 'float3 _WorldSpaceCameraPos', a built-in variable

Shader "QING/BillBoard"
{
    Properties
    {
        _MainTex ("MainTexture", 2D) = "white" {}
        _VerticalBillBoard ("VerticalBillBoard", Range(0, 1)) = 1
        _Color("Color Tint", Color) = (1, 1, 1, 1)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off
        ZTest Always
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
                float4 tangent: TANGENT;
                float3 normal: NORMAL;
                float4 color:COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _VerticalBillBoard;
            float4 _Color;
            // float3 _WorldSpaceCameraPos;
            
            
            void CalcOrthonormalBasis(float3 dir,out float3 right,out float3 up)
            {
                up    = abs(dir.y) > 0.999f ? float3(0,0,1) : float3(0,1,0);     
                right = normalize(cross(up,dir));       
                up    = cross(dir,right);   
            }

            v2f vert (appdata v)
            {
                /*v2f o;
                float3 center = float3(0,0,0);
                float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 normalDir = viewer - center;

                normalDir.y = normalDir.y * _VerticalBillBoard;
                normalDir = normalize(normalDir);

                float3 upDir = abs(normalDir.y) > 0.999? float3(0,0,1) : float3(0, 1, 0);
                float3 rightDir = normalize(cross(upDir, normalDir));
                upDir = normalize(cross(normalDir, rightDir));

                float3 centerOffs = v.vertex.xyz - center;
                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
            
                o.vertex = UnityObjectToClipPos(float4(localPos, 1));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;*/

                // 始终朝向摄像机
                /*v2f o;
                float4 ori=mul(UNITY_MATRIX_MV,float4(0,0,0,1));
                float4 vt=v.vertex;
                vt.y=vt.z;//这个平面是沿xz平面 展开的
                vt.z=0;//所以只关心其平面上的信息

                //通过加上Object Space的原点在ViewSpace的信息，保持其透视大小
                vt.xyz+=ori.xyz;//result is vt.z==ori.z ,so the distance to camera keeped ,and screen size keeped
                o.vertex=mul(UNITY_MATRIX_P,vt);

                o.uv= TRANSFORM_TEX(v.uv, _MainTex);
                return o;*/

                
                
                v2f o;
                
                fixed3 center = fixed3(0.0, 0.0, 0.0);
                //float3  centerOffs  = float3(float(0.5).xx - v.color.rg,0) * v.uv.xyy;
                //float3    centerOffs  = float3(float(0.5).xx - v.color.rg,0) * v.color.bbb*256;
                float3  centerOffs = v.vertex.xyz - center;
                float3  centerLocal = v.vertex.xyz - centerOffs.xyz;
                // 基于物体空间的视角方向
                float3  viewerLocal = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));         
                //    
                float3  normalDir    = viewerLocal - center;
                        
                normalDir.y =normalDir.y * _VerticalBillBoard;
                
                float3  rightLocal;
                float3  upLocal;
                
                CalcOrthonormalBasis(normalize(normalDir) ,rightLocal,upLocal);

                float3  BBNormal   = rightLocal * v.normal.x + upLocal * v.normal.y;
                float3  BBLocalPos = center + (rightLocal * centerOffs.x + upLocal * centerOffs.y);    
                o.uv    = v.uv.xy;
                o.vertex   = UnityObjectToClipPos(float4(BBLocalPos,1));
                                
                return o;
           
            }


            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 color = tex2D(_MainTex, i.uv);
                color.rgb *= _Color.rgb;
                return color;
            }
            ENDCG
        }
    }
}
