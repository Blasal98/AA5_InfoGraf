Shader "Unlit/PBR_Shader"
{
	Properties
	{
		 _objectColor("Main Texture",2D) = "red" {}
		 _ambientInt("Ambient int", Range(0,1)) = 0.25
		 _ambientColor("Ambient Color", Color) = (0,0,0,1)

		 _diffuseInt("Diffuse int", Range(0,1)) = 1


		_Roughness("Roughness",Range(0,1)) = 1
		_metallicSample("Metallic",Range(0.1,1)) = 1

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


				 float _ambientInt;//How strong it is?
				 fixed4 _ambientColor;
				 float _diffuseInt;


				 float4 _directionalLightDir;
				 float4 _directionalLightColor;
				 float _directionalLightIntensity;
				 float _Roughness;
				 float _metallicSample;

				 static const float Pi = 3.14159265359;


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

				 /*------------------FRESNEL----------------*/

				 float fresnel_component(float f0, float product)
				 {

					 return f0 + (1.0 - f0) * pow(1.0 - product, 5.0);// <-- Asi es como lo encontre maioritariamente en internet
					 //return pow(f0 + (1.0 - f0) * (1.01 - product), 5.0); //<-- Asi es como esta en los apuntes
				 }


				 /*----------------DISTRIBURION-------------*/
				 float ggxdistribution_component(float halfVec, float roughness) {

					 halfVec = max(halfVec, 0);

					 float roughness2 = pow(roughness, 2);

					 float denominator = pow(halfVec, 2) * (roughness2 - 1) + 1;

					 float ggxdistri = roughness2 / (Pi * pow(denominator, 2));

					 return ggxdistri;

				 }



				 /*------------------GEOMETRY---------------*/


				 float ggxGeometry_component(float3 viewVec, float roughness, float3 normal) {

					 float roughness2 = pow(roughness, 2);

					 float normDotCam = max(dot(normal, viewVec), 0);

					 //	float ggxGeometry = (2 * normDotCam) / (normDotCam + sqrt(roughness2 + (1 - roughness2) * pow(normDotCam, 2)));

						 float ggxGeometry = (normDotCam / (normDotCam * (1 - (roughness2 * 0.5)) + (roughness2 * 0.5)));

						 return ggxGeometry;

					 }



					 float BRDF(float roughness, float q, float3 viewVec, float3 normal, float3 lightDir , float3 halfVec) {

						 float3 halfDir = halfVec;

						 //return ggxdistribution_component(dot(halfVec, normal), roughness) * fresnel_component(q, dot(halfVec, viewVec));


						 //return (ggxdistribution_component(dot(halfVec, normal), roughness) * fresnel_component(q, dot(halfVec, viewVec))* ggxGeometry_component(viewVec, roughness, normal)) / dot(normal, viewVec);
						 //return 4.0 * max(dot(normal, lightDir), 0) * max(dot(normal, viewVec), 0) ;

						 return
							 (fresnel_component(q, dot(halfVec, viewVec))
								 * ggxdistribution_component(dot(halfVec, normal), roughness)
								 * ggxGeometry_component(viewVec, roughness, normal)
								 )
							 /*/
							 (4.0 * dot(normal, lightDir)* dot(normal, viewVec))*/;

				 }



				 fixed4 frag(v2f i) : SV_Target
				 {

					 fixed4 ambientComp = _ambientColor * _ambientInt;
					 fixed4 finalColor = ambientComp;

					 float3 viewVec;
					 float3 halfVec;
					 float3 difuseComp = float4(0, 0, 0, 1);
					 float3 specularComp;
					 float3 lightColor;
					 float3 lightDir;

					 //Directional light properties
					 lightColor = _directionalLightColor.xyz;
					 lightDir = normalize(_directionalLightDir);

					 //Diffuse componenet
					 difuseComp = lightColor * _diffuseInt * clamp(dot(lightDir, i.worldNormal),0,1);

					 //Specular component	
					 viewVec = normalize(_WorldSpaceCameraPos - i.wPos);

					 //blinnPhong
					 halfVec = normalize(viewVec + lightDir);

					 specularComp = BRDF(_Roughness, _metallicSample ,  viewVec, i.worldNormal, lightDir,  halfVec);

					 //Sum
					 finalColor += clamp(float4(_directionalLightIntensity * (difuseComp + specularComp),1),0,1);

					 fixed4 texureFinal = tex2D(_objectColor, i.uv * _objectColor_ST);

					 //return BRDF(_Roughness, _metallicSample, viewVec, i.worldNormal, lightDir, halfVec) / (4.0 * dot(i.worldNormal, lightDir) * dot(i.worldNormal, viewVec));

					 return  finalColor * texureFinal;
				 }

				 ENDCG
			 }
		 }
}
