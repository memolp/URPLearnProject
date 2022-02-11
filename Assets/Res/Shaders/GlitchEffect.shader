Shader "QING/Glitch Effect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FrequencyR ("FrequencyR", float) = 20
        _Frequency ("Frequency", float) = 20
        _Fill ("Fill", Range(0, 1)) = 0.8
        _ChromAberrAmountX("Chromatic aberration amount X", float) = 0
        _ChromAberrAmountY("Chromatic aberration amount Y", float) = 0
        _RightStripesAmount("Right stripes amount", float) = 1
        _RightStripesFill("Right stripes fill", range(0, 1)) = 0.7
        _LeftStripesAmount("Left stripes amount", float) = 1
        _LeftStripesFill("Left stripes fill", range(0, 1)) = 0.7
        _DisplacementAmount("Displacement amount", vector) = (0, 0, 0, 0)
        _WavyDisplFreq("Wavy displacement frequency", float) = 10
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
            float _Frequency;
            float _FrequencyR;
            float _Fill;
            float _ChromAberrAmountX;
            float _ChromAberrAmountY;
            fixed4 _DisplacementAmount;
            float _DesaturationAmount;
            float _RightStripesAmount;
            float _RightStripesFill;
            float _LeftStripesAmount;
            float _LeftStripesFill;
            float _WavyDisplFreq;

            float random(float2 input)
            {
                return frac(sin(dot(input, float2(12.9898,78.233)))* 43758.5453123);
            }

           /* fixed4 frag(v2f i):SV_Target
            {
                // 使用2次随机条纹 进行位移 为了简化没有对两个随机的参数单独设置
                float stripes1 = step(_Fill, random( floor(i.uv.y * _FrequencyR)));
                float stripes2 = step(_Fill*0.5, random( floor(i.uv.y * _FrequencyR)));

                // 波浪条纹，进行位移
                float4 red = fixed4(1, 0, 0, 1);
                float4 green = fixed4(0, 1, 0, 1);
                float sinY = sin(i.uv.y * _Frequency); // [-1, 1]
                sinY = (sinY + 1) * 0.5; // [0, 1]
                float4 waveY = lerp(red, green, sinY);
                // 这两个也可以外部设置
                float offsetV = 0.01;
                float offsetR = 0.02;
                // 两次的随机获取
                float rx =  stripes1 * offsetR - stripes2 * offsetR;
                // 如果是红色返回offsetV， 否则返回-offsetV
                float x = waveY.x * offsetV - waveY.y * offsetV;
                // 色差
                fixed4 col1 = tex2D(_MainTex, i.uv + fixed2(x + 0.1 + rx, 0));
                fixed4 col2 = tex2D(_MainTex, i.uv + fixed2(x + rx, 0));
                fixed4 col3 = tex2D(_MainTex, i.uv + fixed2(x + rx - 0.1, 0) );

                return fixed4(col1.r, col2.g, col3.b, 1);
            }*/

            /*fixed4 frag (v2f i) : SV_Target 
            {
                fixed2 _ChromAberrAmount = fixed2(_ChromAberrAmountX, _ChromAberrAmountY);
 
 
                //Stripes section
                float stripesRight = floor(i.uv.y * _RightStripesAmount);
                stripesRight = step(_RightStripesFill, random(float2(stripesRight, stripesRight)));
 
                float stripesLeft = floor(i.uv.y * _LeftStripesAmount);
                stripesLeft = step(_LeftStripesFill, random(float2(stripesLeft, stripesLeft)));
                //Stripes section
 
                fixed4 wavyDispl = lerp(fixed4(1,0,0,1), fixed4(0,1,0,1), (sin(i.uv.y * _WavyDisplFreq) + 1) / 2);
 
                //Displacement section
                fixed2 displUV = (_DisplacementAmount.xy * stripesRight) - (_DisplacementAmount.xy * stripesLeft);
               displUV += (_DisplacementAmount.zw * wavyDispl.r) - (_DisplacementAmount.zw * wavyDispl.g);
                //Displacement section
 
                //Chromatic aberration section
                float chromR = tex2D(_MainTex, i.uv + displUV + _ChromAberrAmount).r;
                float chromG = tex2D(_MainTex, i.uv + displUV).g;
                float chromB = tex2D(_MainTex, i.uv + displUV - _ChromAberrAmount).b;
                //Chromatic aberration section
                 
                fixed4 finalCol = fixed4(chromR, chromG, chromB, 1);
                 
                return finalCol;
            }*/
            // 有动画效果。
             fixed4 frag (v2f i) : SV_Target 
             {
                float _GlitchEffect = (sin(_Time.y) + 1)  * 0.5;
                fixed2 _ChromAberrAmount = fixed2(_ChromAberrAmountX, _ChromAberrAmountY);
 
                fixed4 displAmount = fixed4(0, 0, 0, 0);
                fixed2 chromAberrAmount = fixed2(0, 0);
                float rightStripesFill = 0;
                float leftStripesFill = 0;
                //Glitch control
                if (frac(_GlitchEffect) < 0.8) {
                    rightStripesFill = lerp(0, _RightStripesFill, frac(_GlitchEffect) * 2);
                    leftStripesFill = lerp(0, _LeftStripesFill, frac(_GlitchEffect) * 2);
                }
                if (frac(_GlitchEffect) < 0.5) {
                    chromAberrAmount = lerp(fixed2(0, 0), _ChromAberrAmount.xy, frac(_GlitchEffect) * 2);
                }
                if (frac(_GlitchEffect) < 0.33) {
                    displAmount = lerp(fixed4(0,0,0,0), _DisplacementAmount, frac(_GlitchEffect) * 3);
                }
 
                //Stripes section
                float stripesRight = floor(i.uv.y * _RightStripesAmount);
                stripesRight = step(rightStripesFill, random(float2(stripesRight, stripesRight)));
 
                float stripesLeft = floor(i.uv.y * _LeftStripesAmount);
                stripesLeft = step(leftStripesFill, random(float2(stripesLeft, stripesLeft)));
                //Stripes section
 
                fixed4 wavyDispl = lerp(fixed4(1,0,0,1), fixed4(0,1,0,1), (sin(i.uv.y * _WavyDisplFreq) + 1) / 2);
 
                //Displacement section
                fixed2 displUV = (displAmount.xy * stripesRight) - (displAmount.xy * stripesLeft);
                displUV += (displAmount.zw * wavyDispl.r) - (displAmount.zw * wavyDispl.g);
                //Displacement section
 
                //Chromatic aberration section
                float chromR = tex2D(_MainTex, i.uv + displUV + chromAberrAmount).r;
                float chromG = tex2D(_MainTex, i.uv + displUV).g;
                float chromB = tex2D(_MainTex, i.uv + displUV - chromAberrAmount).b;
                //Chromatic aberration section
                 
                fixed4 finalCol = fixed4(chromR, chromG, chromB, 1);
                 
                return finalCol;
            }
            ENDCG
        }
    }
}