Shader "QING/NoiseEffectFull"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CellSize ("Cell Size", Range(0, 2)) = 2
        _Roughness ("Roughness", Range(1, 8)) = 3
        _Persistance ("Persistance", Range(0, 1)) = 0.4
        _Amplitude("Amplitude", Range(0, 10)) = 1
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
                float3 worldPos: TEXCOORD1;
            };

            #define OCTAVES 4 

            float _CellSize;
            float _Roughness;
            float _Persistance;
            float _Amplitude;

            /** 3维坐标随机 */
            float rand3dTold(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719))
            {
                // dotDir 传入不同的值可以做到不同的随机效果，如果是相同的值就会产生一样的随机结果。
                // 不加sin会导致移动过程随机也会往高的移动
                float3 smallValue = sin(value);
                // 取两个向量的点积结果，由于数据非常大，取小数部分。
                float random = dot(smallValue, dotDir);
                // 将结果乘以一个很大的数来造成随机效果
                random = frac(sin(random) * 143758.5453);
                return random;
            }

            float rand2dTold(float2 value, float2 dotDir = float2(12.9898, 78.233))
            {
                float2 smallValue = sin(value);
                float random = dot(smallValue, dotDir);
                random = frac(sin(random) * 143758.5453);
                return random;
            }

            float rand1dTold(float value, float mutator = 0.546)
            {
                float random = frac(sin(value + mutator) * 143758.5453);
                return random;
            }


            float2 rand3dTo2d(float3 value)
            {
                return float2(
                    rand3dTold(value, float3(12.989, 78.233, 37.719)),
                    rand3dTold(value, float3(39.346, 11.135, 83.155))
                );
            }

            float2 rand2dTo2d(float2 value)
            {
                return float2(
                    rand2dTold(value, float2(12.989, 78.233)),
                    rand2dTold(value, float2(39.346, 11.135))
                );
            }

            float2 rand1dTo2d(float value)
            {
                return float2(
                    rand1dTold(value, 3.9812),
                    rand1dTold(value, 7.1536)
                );
            }

            /** 随机3维的结果 */
            float3 rand3dTo3d(float3 value)
            {
                return float3(
                    rand3dTold(value, float3(12.989, 78.233, 37.719)),
                    rand3dTold(value, float3(39.346, 11.135, 83.155)),
                    rand3dTold(value, float3(73.156, 52.235, 09.151))
                );
            }

            float3 rand2dTo3d(float2 value){
                return float3(
                    rand2dTold(value, float2(12.989, 78.233)),
                    rand2dTold(value, float2(39.346, 11.135)),
                    rand2dTold(value, float2(73.156, 52.235))
                );
            }

            float3 rand1dTo3d(float value){
                return float3(
                    rand1dTold(value, 3.9812),
                    rand1dTold(value, 7.1536),
                    rand1dTold(value, 5.7241)
                );
            }

             inline float easeIn(float interpolator)
            {
                return interpolator * interpolator;
            }

            inline float easeOut(float interpolator)
            {
                return 1 - easeIn(1 - interpolator);
            }

            inline float easeInOut(float interpolator)
            {
                float easeInValue = easeIn(interpolator);
                float easeOutValue = easeOut(interpolator);
                return lerp(easeInValue, easeOutValue, interpolator);
            }

            // Perlin 柏林噪声
            float valueNoise2d(float2 value)
            {
                float upperLeft = rand2dTold(float2(floor(value.x), ceil(value.y)));
                float upperRight = rand2dTold(float2(ceil(value.x), ceil(value.y)));
                float lowerLeft = rand2dTold(float2(floor(value.x), floor(value.y)));
                float lowerRight = rand2dTold(float2(ceil(value.x), floor(value.y)));

                float interpolatorX = easeInOut(frac(value.x));
                float interpolatorY = easeInOut(frac(value.y));

                float upperCells = lerp(upperLeft, upperRight, interpolatorX);
                float lowerCells = lerp(lowerLeft, lowerRight, interpolatorX);

                float noise = lerp(lowerCells, upperCells, interpolatorY);
                return noise;
            }

            float valueNoise1d(float value)
            {
                 float prev = rand1dTold(floor(value));
                float next = rand1dTold(ceil(value));
                float interpolator = frac(value);
                interpolator = easeInOut(interpolator);
                float noise = lerp(prev, next, interpolator);
                // float dist = abs(noise - i.worldPos.y);
                // float pixedHeight = fwidth(i.worldPos.y);
                // float lineIn = smoothstep(0, pixedHeight, dist);
                return noise;
            }

            float ValueNoise3d(float3 value)
            {
                float interpolatorX = easeInOut(frac(value.x));
                float interpolatorY = easeInOut(frac(value.y));
                float interpolatorZ = easeInOut(frac(value.z));

                float cellNoiseZ[2];
                [unroll]
                for(int z=0;z<=1;z++){
                    float cellNoiseY[2];
                    [unroll]
                    for(int y=0;y<=1;y++){
                        float cellNoiseX[2];
                        [unroll]
                        for(int x=0;x<=1;x++){
                            float3 cell = floor(value) + float3(x, y, z);
                            cellNoiseX[x] = rand3dTold(cell);
                        }
                        cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
                    }
                    cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
                }
                float noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
                return noise;
            }

            float3 ValueNoise3dColor(float3 value)
            {
                float interpolatorX = easeInOut(frac(value.x));
                float interpolatorY = easeInOut(frac(value.y));
                float interpolatorZ = easeInOut(frac(value.z));

                float3 cellNoiseZ[2];
                [unroll]
                for(int z=0;z<=1;z++){
                    float3 cellNoiseY[2];
                    [unroll]
                    for(int y=0;y<=1;y++){
                        float3 cellNoiseX[2];
                        [unroll]
                        for(int x=0;x<=1;x++){
                            float3 cell = floor(value) + float3(x, y, z);
                            cellNoiseX[x] = rand3dTo3d(cell);
                        }
                        cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
                    }
                    cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
                }
                float3 noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
                return noise;
            }

            // 分层噪声
            float sampleLayeredNoise(float value)
            {
                float noise = 0;
                float frequency = 1;
                float factor = 1;

                [unroll]
                for(int i=0; i<OCTAVES; i++){
                    noise = noise + valueNoise1d(value * frequency + i * 0.72354) * factor;
                    factor *= _Persistance;
                    frequency *= _Roughness;
                }
                return noise;
            }

            float sampleLayeredNoise2D(float2 value)
            {
                float noise = 0;
                float frequency = 1;
                float factor = 1;

                [unroll]
                for(int i=0; i<OCTAVES; i++){
                    noise = noise + valueNoise2d(value * frequency + i * 0.72354) * factor;
                    factor *= _Persistance;
                    frequency *= _Roughness;
                }
                return noise;
            }

            float sampleLayeredNoise3D(float3 value)
            {
                float noise = 0;
                float frequency = 1;
                float factor = 1;

                [unroll]
                for(int i=0; i<OCTAVES; i++){
                    noise = noise + ValueNoise3d(value * frequency + i * 0.72354) * factor;
                    factor *= _Persistance;
                    frequency *= _Roughness;
                }
                return noise;
            }

            float voronoiNoise(float2 value)
            {
                float2 baseCell = floor(value);

                float minDistToCell = 10;
                [unroll]
                for(int x=-1; x<=1; x++){
                    [unroll]
                    for(int y=-1; y<=1; y++){
                        float2 cell = baseCell + float2(x, y);
                        float2 cellPosition = cell + rand2dTo2d(cell);
                        float2 toCell = cellPosition - value;
                        float distToCell = length(toCell);
                        if(distToCell < minDistToCell){
                            minDistToCell = distToCell;
                        }
                    }
                }
                return minDistToCell;
            }

            float2 voronoiNoise2D(float2 value)
            {
                float2 baseCell = floor(value);

                float minDistToCell = 10;
                float2 closestCell;
                [unroll]
                for(int x=-1; x<=1; x++){
                    [unroll]
                    for(int y=-1; y<=1; y++){
                        float2 cell = baseCell + float2(x, y);
                        float2 cellPosition = cell + rand2dTo2d(cell);
                        float2 toCell = cellPosition - value;
                        float distToCell = length(toCell);
                        if(distToCell < minDistToCell){
                            minDistToCell = distToCell;
                            closestCell = cell;
                        }
                    }
                }
                float random = rand2dTold(closestCell);
                return float2(minDistToCell, random);
            }

            v2f vert(appdata v)
            {
                v2f o;
               
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                // float3 value = mul(unity_ObjectToWorld, v.vertex) / _CellSize;
                // float noise = sampleLayeredNoise3D(value) + 0.5;
                // v.vertex.y += noise * _Amplitude;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            sampler2D _MainTex;

           

            fixed4 frag(v2f i):SV_Target
            {
                // float3 value = i.worldPos.xyz / 0.1;
                // float noise = ValueNoise3d(value);
                // float2 value = i.worldPos.xy / _CellSize;
                // float3 value = i.worldPos.xyz / _CellSize;
                // float noise = sampleLayeredNoise2D(value);
                // float noise = sampleLayeredNoise3D(value);
                // float3 color = float3(noise, noise, noise);
                // 1维的需要这样才能是一条线
                // float dist = abs(noise - i.worldPos.y);
                // float pixedHeight = fwidth(i.worldPos.y);
                // float lineIn = smoothstep(2*pixedHeight, pixedHeight, dist);
                // float3 color = lerp(1, 0, lineIn);
                float2 value = i.worldPos.xy / _CellSize;
                float noise = voronoiNoise2D(value).y;//voronoiNoise(value);
                float3 color = rand1dTo3d(noise);//float3(noise, noise, noise);

                // float3 color = fixed3(1,1,1);
                return float4(color, 1);
            }
            ENDCG
        }
    }
}