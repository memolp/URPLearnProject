Shader "QING/CustomMask01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 圆的半径
        _Radius ("Radius", float) = 1.0
        // 这个圆的中心点
        _CenterX("Center X", float) = 0.5
        _CenterY("Center Y", float) = 0.5
        // 整个屏幕或者说这个效果所在的平面的大小比例
        _SizeX("Size X", float) = 1
        _SizeY("Size Y", float) = 1
        _Hardness ("Hardness", float) = 1
        // 是否反转，以及圆边缘的过渡区域
        _Invert ("Invert", Range(-1, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True"}
        LOD 100
        Cull Off
        ZWrite Off
        ZTest Always
        
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
                float2 uv:TEXCOORD0;
                float4 vertex: SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float _Radius;
            float _CenterX;
            float _CenterY;
            float _SizeX;
            float _SizeY;
            float _Hardness;
            float _Invert;

            fixed4 frag(v2f i):SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 center = float2(_CenterX, _CenterY);
                float2 resolution = float2(_SizeX, _SizeY);
                // 计算当前uv的坐标离中心点的距离（*resolution 将根据实际的屏幕或平面尺寸大小比例这样得到的是正圆）
                float dist = length((i.uv - center) *resolution);
                // 长度/半径，如果大于1说明在圆外，否则在圆内
                float circle = saturate(dist / _Radius); 
                // 当circle小于1时，执行pow操作会变得更小。 _Hardness用来控制这个
                float circleAlpha = pow(circle, pow(_Hardness, 2));
                // _Invert 控制是否进行反转，遮罩是影响这个圆，还是圆外。并且还可以控制渐变
                float aZhenshu = circleAlpha * _Invert;  // 大于0表示圆内
                float aFushu = (1 - circleAlpha) * (-_Invert); // 小于0 表示圆外
                // 不写判断采用lerp操作
                //  _Invert > 0 ? circleAlpha * _Invert:(1 - circleAlpha) * (-_Invert);
                float a = lerp(aFushu, aZhenshu,step(0, _Invert));
                col.rgb = col.rgb * a;  // 这样不显示的部分全是黑色（可以通过a通道搞，但是需要clip）
                return col;
            }
            ENDCG
        }
    }
}