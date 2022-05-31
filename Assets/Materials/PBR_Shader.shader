Shader "Unlit/PBR_Shader"
{
	// BDRF(l,v) = Fresnel(l,h) * Geometry(l,v,h) * Distribution(h) / (4 * (n*l) * (n*v))
	// l es el vector light   [del vertice a la luz]
	// v es el vector view    [del vertice a la camara]
	// n es el vector normal  [normal del vertice]
	// h es el vector half    [bisectriz de vectores l-v]

	// FresnelShlick(q,l,h) = q + ((1 - q) * (1 - h * l)) ^ 5
	// q es un escalar que proporciona el material

	Properties
	{
		 _objectColor("Main Texture",2D) = "red" {}

		_ambientColor("Ambient Color", Color) = (0,0,0,1)

		_ambientInt("Ambient int", Range(0,1)) = 0.25

		_diffuseInt("Diffuse int", Range(0,1)) = 1

		//_scecularExp("Specular exponent",Float) = 2.0
		_fresnelIntensity("Fresnel int", Range(0.0, 1.0)) = 1.0
		_distributionRoughness("Distribution roughness", Range(0.0001, 1.0)) = 0.0001


		_pointLightPos("Point light Pos",Vector) = (0,0,0,1)
		_pointLightColor("Point light Color",Color) = (0,0,0,1)
		_pointLightIntensity("Point light Intensity",Float) = 1

		_directionalLightDir("Directional light Dir",Vector) = (0,1,0,1)
		_directionalLightColor("Directional light Color",Color) = (0,0,0,1)
		_directionalLightIntensity("Directional light Intensity",Float) = 1
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ POINT_LIGHT_ON 
			#pragma multi_compile __ DIRECTIONAL_LIGHT_ON
			#include "UnityCG.cginc"

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

			sampler2D _objectColor;
			float4 _objectColor_ST;
			float4 _objectColor_SO;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _objectColor);
				o.uv = v.uv;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}



			float _ambientInt;//How strong it is?
			fixed4 _ambientColor;
			float _diffuseInt;
			//float _scecularExp;
			float _fresnelIntensity;
			float _distributionRoughness;

			float4 _pointLightPos;
			float4 _pointLightColor;
			float _pointLightIntensity;

			float4 _directionalLightDir;
			float4 _directionalLightColor;
			float _directionalLightIntensity;

			//BDRF
			float Fresnel(float3 lightVector, float3 halfVector) {
				return _fresnelIntensity + pow((1 - _fresnelIntensity) * (1 - dot(halfVector, lightVector)), 5);
			}
			float Distribution(float3 normalVector, float3 halfVector) {
				return pow(_distributionRoughness, 2) / (3.14159 * pow(pow(dot(normalVector,halfVector),2) * (pow(_distributionRoughness,2) - 1) + 1, 2));
			}
			float Geometry(float3 lightVector, float3 viewVector, float3 normalVector, float3 halfVector) {
				return dot(normalVector,lightVector) * dot(normalVector, viewVector) / max(dot(normalVector,lightVector), dot(normalVector, viewVector));
			}
			float BRDF(float3 lightVector, float3 viewVector, float3 normalVector, float3 halfVector) {
				return
					Fresnel(lightVector, halfVector) *
					Geometry(lightVector, viewVector, normalVector, halfVector) *
					Distribution(normalVector, halfVector) /
					(4 * dot(normalVector, lightVector) * dot(normalVector, viewVector));
			}

			fixed4 frag(v2f i) : SV_Target
			{


				//3 phong model light components
				//We assign color to the ambient term		
				fixed4 ambientComp = _ambientColor * _ambientInt;//We calculate the ambient term based on intensity
				fixed4 finalColor = ambientComp;

				float3 viewVec;
				float3 halfVec;
				float3 difuseComp = float4(0, 0, 0, 1);
				float3 specularComp = float4(0, 0, 0, 1);
				float3 lightColor;
				float3 lightDir;
				fixed4 texureFinal = float4(0, 0, 0, 1);
#if DIRECTIONAL_LIGHT_ON

				//Directional light properties
				lightColor = _directionalLightColor.xyz;
				lightDir = normalize(_directionalLightDir);

				//Diffuse componenet
				difuseComp = lightColor * _diffuseInt * clamp(dot(lightDir, i.worldNormal),0,1);

				//Specular component	
				viewVec = normalize(_WorldSpaceCameraPos - i.wPos);

				//Specular component
				//phong
				//float3 halfVec = reflect(-lightDir, i.worldNormal);
				//fixed4 specularComp = lightColor * pow(clamp(dot(halfVec, viewVec),0,1), _scecularExp);

				//blinnPhong
				halfVec = normalize(viewVec + lightDir);
				//specularComp = lightColor * pow(max(dot(halfVec, i.worldNormal),0), _scecularExp);
				specularComp = lightColor * BRDF(lightDir, viewVec, i.worldNormal, halfVec);
				//specularComp *= max(dot(viewVec, lightDir), 0);


				//Sum
				finalColor += clamp(float4(_directionalLightIntensity * (difuseComp + specularComp),1),0,1);
				texureFinal = tex2D(_objectColor, i.uv * _objectColor_ST);

#endif
#if POINT_LIGHT_ON
				//Point light properties
				lightColor = _pointLightColor.xyz;
				lightDir = _pointLightPos - i.wPos;
				float lightDist = length(lightDir);
				lightDir = lightDir / lightDist;
				//lightDir *= 4 * 3.14;

				//Diffuse componenet
				difuseComp = lightColor * _diffuseInt * clamp(dot(lightDir, i.worldNormal), 0, 1) / lightDist;

				//Specular component	
				viewVec = normalize(_WorldSpaceCameraPos - i.wPos);

				//Specular component
				//phong
				//float3 halfVec = reflect(-lightDir, i.worldNormal);
				//fixed4 specularComp = lightColor * pow(clamp(dot(halfVec, viewVec),0,1), _scecularExp);

				//blinnPhong
				halfVec = normalize(viewVec + lightDir);
				//specularComp = lightColor * pow(max(dot(halfVec, i.worldNormal), 0), _scecularExp) / lightDist;
				specularComp = lightColor * BRDF(lightDir, viewVec, i.worldNormal, halfVec);
				//specularComp *= max(dot(viewVec, lightDir), 0);


				//Sum
				finalColor += clamp(float4(_pointLightIntensity * (difuseComp + specularComp),1),0,1);
				texureFinal = tex2D(_objectColor, i.uv * _objectColor_ST);

#endif
				//pointLight

				return finalColor * texureFinal;
			}
			ENDCG
		}
	}
}
