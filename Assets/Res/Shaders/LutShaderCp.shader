Shader "QING/LUTShaderCP"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LUT("LUT", 2D) = "white" {}
        _Contribution("Contribution", Range(0, 1)) = 1
    }
    SubShader
    {
        //Tags { "RenderType"="Opaque" }
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True"}
        LOD 100
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _LUT;
            float4 _LUT_TexelSize;
            float _Contribution;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            #define COLORS 64.0
            #define ROWS 8.0
            /*
             LUT 的工作原理：整个想法是我们将场景的颜色映射到基于颜色立方体的新颜色。
             r通道表示，每个小方块的从左到右是0-1渐变，也就是r是沿着横轴查找。
             g通道表示，g是沿着纵轴从上到下查找。 两个确定（0，0）在左上角。
             b通道表示每个小方格是代表一个灰度。
             所以查找输入rgb时，先通过b的值找到对应小方格。然后通过以小方格的左上角为原点，r和b的值为坐标查找到对应像素，这个像素的rgb值就是经过lut映射后的值。
            */
            fixed4 frag (v2f i) : SV_Target
            {
                float maxColor = COLORS - 1.0;

                fixed4 col = saturate(tex2D(_MainTex, i.uv)); //[0, 1]

                // 确定对应的方格 b:[0,1] 对应 [0,63] 8*8
                float cell = col.b * maxColor;
                // 通过对应的方格找到在8*8图中的行和列
                float cell_y = floor(cell / 8.0); 
                float cell_x = floor(cell) - cell_y * 8.0;

                float halfColX = cell_x / ROWS + 0.5 / _LUT_TexelSize.z;
                float halfColY = cell_y / ROWS + 0.5 / _LUT_TexelSize.w;

                // 
                //cell_x / ROWS + 0.5 / _LUT_TexelSize.z + col.r * (1.0/ROWS - 1.0 / _LUT_TexelSize.z)
                //cell_x / ROWS + 0.5 / _LUT_TexelSize.z + col.r/ ROWS - col.r / _LUT_TexelSize.z);

                //(cell_x + col.r)/ROWS + (0.5 - col.r) / _LUT_TexelSize.z;

                //float r = halfColX + col.r * (1.0/ROWS - 1.0 / 512);
                //float g = halfColY + col.g * (1.0/ROWS - 1.0 / 512);
                // (第几列 + r的颜色值) / 总列数 = 得到这个颜色值的新列数
                // （0.5 - r的颜色值）/ 像素宽度 = 基于中心的左右的位置
                float r = (cell_x+ col.r) /ROWS + (0.5 - col.r) / _LUT_TexelSize.z;
                float g = (cell_y+ col.g )/ROWS + (0.5 - col.g) / _LUT_TexelSize.w;

				float4 gradedCol = tex2D(_LUT, fixed2(r, 1 - g));
                
                return gradedCol;
                //return lerp(col, gradedCol, _Contribution);
            }
            /*
            fixed4 frag (v2f i) : SV_Target
            {
                float maxColor = COLORS - 1.0;
                fixed4 col = saturate(tex2D(_MainTex, i.uv)); //[0, 1]

                // 确定对应的方格
                float Bcolor = floor(col.b * maxColor);

				float2 quad1;
                //获取竖向和横向的片段位置（共获取2个B值片段位置，并在之后用余数插值）
				quad1.y = floor(floor(Bcolor)/8);
				quad1.x = floor(Bcolor)-(quad1.y*8);

				float2 quad2;
				quad2.y = ceil(floor(Bcolor)/8);
				quad2.x = ceil(Bcolor)-(quad2.y*8);

				float2 uv1;
				float2 uv2;
				//计算UV坐标，并对采样范围左右各缩小0.5
				uv1.x = ((quad1.x)*0.125)+ 0.5/512.0 +((0.125-0.5/512.0)* col.r);
				uv1.y =1-(((quad1.y)*0.125) + 0.5/512.0 +((0.125-0.5/512.0)* col.g));

				uv2.x = ((quad2.x)*0.125)+ 0.5/512.0 +((0.125-0.5/512.0)* col.r);
				uv2.y = 1-(((quad2.y)*0.125)+ 0.5/512.0 +((0.125-0.5/512.0)* col.g));
                              //采样
				fixed4 col1 = tex2D(_LUT,uv1);
				fixed4 col2 = tex2D(_LUT,uv2);
                              //根据B值的灰度插值
				col.rgb = lerp(col1.rgb,col2.rgb, frac(Bcolor));				
				col=fixed4(col.rgb,1.0);
				return col;
            }
            */
            ENDCG
        }
    }
}
