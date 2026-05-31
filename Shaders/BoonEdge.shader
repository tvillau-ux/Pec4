
Shader "Custom/BoonEdge"
{
    Properties
    {
        _MainColor ("Face Color", Color) = (1, 1, 1, 1)
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        _EdgeWidth ("Edge Width", Range(0, 0.05)) = 0.02
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200

        // Pass 1: Filled faces
        Pass
        {
            Name "FILL"
            Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
            };

            fixed4 _MainColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float ndotl = saturate(dot(normalize(i.worldNormal), lightDir)) * 0.5 + 0.5;
                return _MainColor * ndotl;
            }
            ENDCG
        }

        // Pass 2: Wireframe edges
        Pass
        {
            Name "EDGE"
            Cull Off
            Offset -1, -1
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2g
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float3 dist : TEXCOORD0;
            };

            float _EdgeWidth;
            fixed4 _EdgeColor;

            v2g vert(appdata v)
            {
                v2g o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> stream)
            {
                float2 p0 = input[0].pos.xy / input[0].pos.w;
                float2 p1 = input[1].pos.xy / input[1].pos.w;
                float2 p2 = input[2].pos.xy / input[2].pos.w;

                float2 v0 = p2 - p1;
                float2 v1 = p0 - p2;
                float2 v2 = p1 - p0;

                float area = abs(v0.x * v2.y - v0.y * v2.x);

                float2 screenPos0 = input[0].pos.xy * _ScreenParams.xy / input[0].pos.w;
                float2 screenPos1 = input[1].pos.xy * _ScreenParams.xy / input[1].pos.w;
                float2 screenPos2 = input[2].pos.xy * _ScreenParams.xy / input[2].pos.w;

                float edge0 = length(screenPos2 - screenPos1);
                float edge1 = length(screenPos0 - screenPos2);
                float edge2 = length(screenPos1 - screenPos0);

                float height0 = area / edge0;
                float height1 = area / edge1;
                float height2 = area / edge2;

                g2f o;
                o.pos = input[0].pos;
                o.dist = float3(height0, 0, 0);
                stream.Append(o);

                o.pos = input[1].pos;
                o.dist = float3(0, height1, 0);
                stream.Append(o);

                o.pos = input[2].pos;
                o.dist = float3(0, 0, height2);
                stream.Append(o);
            }

            fixed4 frag(g2f i) : SV_Target
            {
                float minDist = min(min(i.dist.x, i.dist.y), i.dist.z);
                float lineWidth = _EdgeWidth * _ScreenParams.y;
                float alpha = 1.0 - smoothstep(lineWidth - 1.0, lineWidth + 1.0, minDist);
                if (alpha < 0.1) discard;
                return _EdgeColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
