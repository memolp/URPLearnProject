Shader "QING/LUTColorGrading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 无压缩，无 mip 贴图，无 sRGB 或 Alpha，Clamp 而不是重复和 0 Aniso Level（如果您首先启用“生成 Mip 贴图”然后禁用它，则可以对其进行修改）
        _LUT("LUT", 2D) = "white" {}
        _Contribution("Contribution", Range(0, 1)) = 1
    }
    SubShader
    {
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
 
            #define COLORS 32.0
 
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
 
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
             
            sampler2D _MainTex;
            sampler2D _LUT;
            float4 _LUT_TexelSize;
            float _Contribution;
 
            fixed4 frag (v2f i) : SV_Target
            {
                float maxColor = COLORS - 1.0;
                //这种色调映射技术应用于 LDR 图像而不是 HDR 
                fixed4 col = saturate(tex2D(_MainTex, i.uv)); //[0, 1]
                // X 和 Y 轴 LUT 纹理像素大小的一半
                float halfColX = 0.5 / _LUT_TexelSize.z;
                float halfColY = 0.5 / _LUT_TexelSize.w;
                float threshold = maxColor / COLORS;
                //  LUT 采样的偏移量
                // 红色通道的偏移量等于：半个纹理像素+通道值*阈值/颜色
                float xOffset = halfColX + col.r * threshold / COLORS;
                // 绿色通道
                float yOffset = halfColY + col.g * threshold;
                //蓝色通道的值
                float cell = floor(col.b * maxColor);
                // LUT 上的 UV 坐标
                //X 坐标将由单元格数除以颜色数确定（以便它开始从第一个单元格的开头一直到最后一个单元格的开头）加上 X 偏移量。
                //Y 坐标就是上面计算的 yOffset。
                float2 lutPos = float2(cell / COLORS + xOffset, yOffset);
                float4 gradedCol = tex2D(_LUT, lutPos);
                 
                return lerp(col, gradedCol, _Contribution);
            }
            ENDCG
        }
    }
}