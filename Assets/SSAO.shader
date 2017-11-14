Shader "d3cr1pt0r/SSAO"
{
	Properties {
		_MainTex ("Main Texture", 2D) = "white" {}
		_SampleRadius ("Sample Radius", Range(0, 0.1)) = 1
		_Bias ("Bias", Range(0, 0.1)) = 0
	}

	SubShader {
		Tags { "RenderType"="Opaque" }

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _CameraDepthNormalsTexture;
			sampler2D _CameraDepthTexture;

			float4x4 _InverseProjectionMatrix;
			float4x4 _InverseViewMatrix;
			float4x4 _ProjectionMatrix;
			float4x4 _ViewMatrix;

			float _SampleRadius;
			float _Bias;

			uniform float4 _RandomDirections[100];

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord0 : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 texcoord0 : TEXCOORD0;
			};

			float getDepth(float2 uv) {
				return tex2D(_CameraDepthTexture, uv).r;
			}

			float3 depthToViewSpacePosition(float depth, float2 uv, float4x4 inverseProjectionMatrix, float4x4 inverseViewMatrix) {
				float4 clipSpacePosition = float4(uv * 2.0 - 1.0, depth, 1.0);
				float4 viewSpacePosition = mul(inverseProjectionMatrix, clipSpacePosition);

				viewSpacePosition /= viewSpacePosition.w;

				//return mul(inverseViewMatrix, viewSpacePosition).xyz;
				return viewSpacePosition.xyz;
			}

			float viewSpacePositionToDepth(float3 worldPosition, float4x4 projectionMatrix, float4x4 viewMatrix) {
				float4 r0 = mul(projectionMatrix, float4(worldPosition, 1.0));
				//r0 = mul(projectionMatrix, r0);
				r0.xyz /= r0.w;
				r0.xy = r0.xy * 0.5 + 0.5;

				return getDepth(r0.xy);
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord0 = v.texcoord0;

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed2 uv = i.texcoord0.xy;
				fixed4 mainTex = tex2D(_MainTex, i.texcoord0);

				float mDepth;
				float3 mNormal;
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.texcoord0), mDepth, mNormal);

				float3 mNormalWorld = mul(_InverseViewMatrix, float4(mNormal, 0.0)).xyz;
				mDepth = getDepth(i.texcoord0.xy);
				float3 worldSpacePosition = depthToViewSpacePosition(mDepth, i.texcoord0.xy, _InverseProjectionMatrix, _InverseViewMatrix);

				float occlusion = 0.0;
				for(int i=0;i<100;i++) {
					float3 randomSamplePointInSphere = worldSpacePosition + _RandomDirections[i] * _SampleRadius;
					float randomSamplePointDepth = viewSpacePositionToDepth(randomSamplePointInSphere, _ProjectionMatrix, _ViewMatrix);

					float rangeCheck = abs(mDepth - randomSamplePointDepth) < _SampleRadius ? 1.0 : 0.0;
					if (randomSamplePointDepth < mDepth - _Bias) {
						occlusion += 0.01 * rangeCheck;
					}
				}

				return mainTex * (1.0 - occlusion);
			}
			ENDCG
		}
	}
}
