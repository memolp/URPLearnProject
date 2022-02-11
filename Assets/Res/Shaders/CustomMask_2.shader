Shader "QING/CustomMask02"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 圆环的半径（注意真正圆环半径是这个+厚度的一半） 
        _Radius ("Radius", float) = 1.0
        // 圆环的厚度
        _Thickness("Thickness", float) = 0.5
        // 这个圆环的中心点
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
            float _Thickness;

            fixed4 frag(v2f i):SV_Target
            {
                // 将半径从0.2 - 1 进行变化，产生波纹涟漪出去
                float _Radius = (sin(_Time.y) + 1) * 0.5;
                float2 center = float2(_CenterX, _CenterY);
                float2 resolution = float2(_SizeX, _SizeY);
                // 计算当前uv的坐标离中心点的距离（*resolution 将根据实际的屏幕或平面尺寸大小比例这样得到的是正圆）
                float dist = length((i.uv - center) *resolution);
                // 厚度的一半
                float rd = _Thickness / 2;
                // 圆环的内半径
                float rc = _Radius - rd; 
                // 长度 - 内半径/厚度，如果大于1说明在圆环内内或者圆环外。否则就在圆环上面
                float circle = saturate(abs(dist - rc) / _Thickness); 
                // 当circle小于1时，执行pow操作会变得更小。 _Hardness用来控制这个
                float circleAlpha = pow(circle, pow(_Hardness, 2));
                // _Invert 控制是否进行反转，遮罩是影响这个圆，还是圆外。并且还可以控制渐变
                float aZhenshu = circleAlpha * _Invert;  // 大于0表示圆内
                float aFushu = (1 - circleAlpha) * (-_Invert); // 小于0 表示圆外
                // 不写判断采用lerp操作
                //  _Invert > 0 ? circleAlpha * _Invert:(1 - circleAlpha) * (-_Invert);
                float a = lerp(aFushu, aZhenshu,step(0, _Invert));
                // 扭曲效果 这个控制偏移的度，表现波纹的强度
                float offetV = 0.01;
                // i.uv / 1.2  这个是保证上面和右边不会出现问题，这个看实际的效果可以随便改
                fixed4 col = tex2D(_MainTex, i.uv / 1.2 + a * offetV);
                return col;
            }
            ENDCG
        }
    }
}