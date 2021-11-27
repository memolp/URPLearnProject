Shader "QING/RadialBlur"
{
    Properties {
  _MainTex ("_MainTex", 2D) = "white" { }
  _Force ("_Force", Range(0, 1)) =  0.2
  _Blend ("_Blend", float) =  0.9
 }
 SubShader
 {
  
  Tags {"Queue"="Transparent"}
  Blend SrcAlpha  OneMinusSrcAlpha
  pass
  {
   CGPROGRAM
   #pragma vertex vert
   #pragma fragment frag
   #include "UnityCG.cginc"
   sampler2D _MainTex;
 
   float4 _MainTex_ST;
   float _Force;
   float _Blend;
   
   struct v2f {
     float4  pos : SV_POSITION;
     float2  uv : TEXCOORD0;
   } ;
   
   //沿径向取颜色均值
   float4 ColorAfterBlur(sampler2D tex,float2 uv,float2 dir)
   {
      float samples[10] = {-0.08,-0.05,-0.03,-0.02,-0.01,0.01,0.02,0.03,0.05,0.08};
      float4 c = float4(0,0,0,0);
      for(int i =0;i<10;i++)
      {
        c +=  tex2D(_MainTex,uv + _Force* dir *samples[i]);
      }
      c/= 10;
      return c;
   }
   v2f vert (appdata_base v)
   {
      v2f o;
      o.pos = UnityObjectToClipPos(v.vertex);
      o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
     return o;
   }
   float4 frag (v2f i) : COLOR
   {
      float4 color_Tex = tex2D(_MainTex,i.uv);
      //获得指向中心点的单位向量
      float2 center = float2(0.5,0.5);
      float2 dir = center - i.uv;
      float len = length(dir);
      dir = normalize(dir);
      float4 c = ColorAfterBlur(_MainTex,i.uv,dir);
      float t = saturate(len * _Blend);
      return lerp(color_Tex,c, t);
   }
   ENDCG
  }
 }
}
