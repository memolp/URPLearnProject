Shader "QING/RadiusCat" {
	Properties{
		_MainTex("Sprite Texture", 2D) = "white"{}
		_RadiusX("Radius X", Range(0, 1)) = 1
        _RadiusY("Radius Y", Range(0, 1)) = 1

	}
		SubShader{
			Tags {
				"Queue" = "Transparent"
				"RenderType" = "Transparent"
				"IgnoreProjector" = "True"
			}

			Cull Off
			Lighting Off
			ZWrite Off
			ZTest Off
			Blend SrcAlpha OneMinusSrcAlpha

			pass {
				CGPROGRAM

				#pragma vertex vert 
				#pragma fragment frag 

				#include "UnityCG.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;
				float _RadiusX;
				float _RadiusY;
				float _Smooth;
				#define PI 3.1416
				#define PI2 6.2832

				struct v2f {
					float4 vertex : POSITION;
					float2 uv: TEXCOORD;
				};

				v2f vert(appdata_base v) {
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
					return o;
				}

				fixed4 frag(v2f i) : COLOR 
                {
                    fixed4 col = tex2D(_MainTex, i.uv);
					float2 dis = (i.uv - float2(0.5, 0.5));
                    // y/x 正切值对应的弧度[-PI, PI]范围 /PI 结果[-1, 1]  /2PI [-0.5, 0.5]
                    // 对于任意不同时等于0的实参数x和y，atan2(y,x)所表达的意思是坐标原点为起点，
                    // 当y>0 , 从一象限到二象限 [0, PI] /2PI (0, 0.5)
                    // 当y<0, 从四象限到三象限 (-0, -PI)   (0, - 0.5)
                    float angle = (atan2(dis.y, dis.x)) / PI2; // [-0.5, 0.5] (负数在三，四象限)
                    // 通过fy fx 取值 1， -1， 0来定义开始消失的位置。
                    // float angle = (atan2(dis.y, dis.x) - atan2(fy, fx)) / PI2; // [-0.5, 0.5] (负数在三，四象限)
                    // 当angle为负数时， (0, -0.5) --> (1, 0.5) 四象限为1，三象限为0.5
                    // 一象限为0， 二，三为0.5， 四象限为1
                    float correctAngle = lerp(angle + 1.0, angle, step(0, angle));
                    
                    // 默认顺时针从1->0 CutValue进度 会从四，三，二，一 
                    // clip函数会将参数小于0的像素点直接丢弃掉
                    //clip(_RadiusX - correctAngle);
                    // 反向逆时针 从1->0 CutValue进度 会从一，二，三，四 
                    // clip(correctAngle - (1 -  _RadiusX)); = clip(_RadiusX + correctAngle - 1)

                    // 控制顺时针还是逆时针
                    int direction = step(1, _RadiusY);
                    float cut_value = lerp(1 - _RadiusX, _RadiusX, step(direction, 0));
                    clip(lerp(direction, 1 - direction, step(correctAngle, cut_value)) - 1);
                    // 其实可以简单使用
                    //int direction = step(1, _RadiusY);
                    //float v = lerp(_RadiusX - correctAngle, _RadiusX + correctAngle - 1, direction);
                    //clip(v);


					return col;
				}

				ENDCG
			}
		}
}