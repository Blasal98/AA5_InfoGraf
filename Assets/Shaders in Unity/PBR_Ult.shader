Shader "Unlit/PBR_Ult"
{
	Properties
	{
		 _texture("Texture",2D) = "Black"{}
		 _ambientInt("Ambient int", Range(0,1)) = 0.25
		 _ambientColor("Ambient Color", Color) = (0,0,0,1)

		 _diffuseInt("Diffuse int", Range(0,1)) = 1
		_scecularExp("Specular exponent",Float) = 2.0

		_metallicness("MetallicParam", Range(0,1)) = 0.5
		_smoothness("SmoothParam", Range(0,1)) = 0.5
	}
		SubShader
		 {
			 Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}

			 Pass
			 {
				 Tags{"LightMode" = "UniversalForward"}
				 HLSLPROGRAM
				 #pragma vertex vert
				 #pragma fragment frag
				 #pragma multi_compile __ DIRECTIONAL_LIGHT_ON
				 #pragma multi_compile  _MAIN_LIGHT_SHADOWS

				 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
				 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
				 #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

				 struct appdata
				 {
					 float4 vertex : POSITION;
					 float2 uv : TEXCOORD0;
					 float3 normal : NORMAL;
				 };

				 struct v2f
				 {
					 float2 uv : TEXCOORD0;
					 float4 vertex : SV_POSITION;
					 float3 worldNormal : TEXCOORD1;
					 float3 wPos : TEXCOORD2;
				 };

				 sampler2D _texture;
				 float4 _texture_ST;

				 float4 ObjectToClipPos(float3 pos)
				 {
					 return mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4 (pos, 1)));
				 }

				 v2f vert(appdata v)
				 {
					 v2f o;
					 o.vertex = ObjectToClipPos(v.vertex);
					 o.uv = TRANSFORM_TEX(v.uv, _texture);
					 o.uv = v.uv;
					 o.worldNormal = TransformObjectToWorldNormal(v.normal);
					 o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					 return o;
				 }

				 float _ambientInt;//How strong it is?
				 half4 _ambientColor;
				 float _diffuseInt;
				 float _scecularExp;

				 float _metallicness;
				 float _smoothness;



				 half4 frag(v2f i) : SV_Target
				 {
					 //3 phong model light components
					 //We assign color to the ambient term		
					 half4 ambientComp = _ambientColor * _ambientInt;//We calculate the ambient term based on intensity
					 half4 finalColor = ambientComp;

					 float3 viewVec;
					 float3 halfVec;
					 float3 difuseComp = float4(0, 0, 0, 1);
					 float3 specularComp = float4(0, 0, 0, 1);
					 float fresnel;
					 float aa;
					 float dotV;
					 float distribution;
					 float dotNL;
					 float dotNV;
					 float dotVH;
					 float geometry;
					 float lightDist;

	 #if SHADOWS_SCREEN
					 half4 clipPos = TransformWorldToHClip(i.wPos);
					 half4 shadowCoord = ComputeScreenPos(i.vertex);
	 #else
					 half4 shadowCoord = TransformWorldToShadowCoord(i.wPos);
	 #endif
					 Light mainLight = GetMainLight(shadowCoord);
					 half3 Direction = mainLight.direction;
					 half3 Color = mainLight.color;
					 half DistanceAtten = mainLight.distanceAttenuation;
					 half ShadowAtten = mainLight.shadowAttenuation;

					 //Directional light properties
					 Color = Color.xyz;
					 Direction = normalize(Direction);

					 //Diffuse componenet
					 difuseComp = Color * _diffuseInt * clamp(dot(Direction, i.worldNormal),0,1);

					 //Specular component	
					 viewVec = normalize(_WorldSpaceCameraPos - i.wPos);

					 //blinnPhong
					 halfVec = normalize(viewVec + Direction);

					 //Fresnel formula
					 fresnel = pow((_metallicness + (1.0 - _metallicness) * (1.0 - dot(Direction, i.worldNormal))), 5.0);

					 //Distribution formula
					 aa = _smoothness * _smoothness;
					 dotV = dot(i.worldNormal, halfVec);
					 dotV = dotV * dotV;
					 distribution = aa / (3.141592f * pow(((dotV * (aa - 1.0f) + 1.0f)), 2.0f));

					 //Geometry formula
					 dotNL = dot(i.worldNormal, Direction);
					 dotNV = dot(i.worldNormal, viewVec);
					 dotVH = dot(viewVec, halfVec);
					 dotVH = dotVH * dotVH;
					 geometry = dotNL * dotNV / dotVH;
					 specularComp = ((fresnel * distribution * geometry) / (4.0 * dot(i.worldNormal, Direction) * dot(i.worldNormal, viewVec)));

					 //Sum
					 finalColor += clamp(float4(DistanceAtten * (difuseComp + specularComp),1),0,1);
					 half4 outTexture = tex2D(_texture, i.uv * _texture_ST);

					 return finalColor * outTexture * DistanceAtten * ShadowAtten;
				  }
				  ENDHLSL
			  }
		 }
}
