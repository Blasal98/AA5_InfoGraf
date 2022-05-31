using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class light : MonoBehaviour
{
    public enum LightType { Point, Directional };
    public LightType type;
    public Vector3 direction;
    public Color color;
    public float intensity;

    public Material mat;

    // Start is called before the first frame update
    void OnEnable()
    {
        direction = transform.forward;
        //mat = ;
        if (type == LightType.Point)
        {
            Shader.EnableKeyword("POINT_LIGHT_ON");
        }
        if (type == LightType.Directional)
            Shader.EnableKeyword("DIRECTIONAL_LIGHT_ON");

    }
    private void OnDisable()
    {
        if (type == LightType.Point)
            Shader.DisableKeyword("POINT_LIGHT_ON");
        if (type == LightType.Directional)
            Shader.DisableKeyword("DIRECTIONAL_LIGHT_ON");
    }
    private void OnDrawGizmos()
    {
        if (type == LightType.Directional)
            Debug.DrawLine(transform.position, transform.position + direction, color);
    }

    // Update is called once per frame
    void Update()
    {
        if (type == LightType.Directional)
        {
            direction = transform.forward;
            mat.SetVector("_directionalLightDir", -direction);
            mat.SetColor("_directionalLightColor", color);
        }
        else if (type == LightType.Point)
        {
            mat.SetVector("_pointLightPos", transform.position);
            mat.SetColor("_pointLightColor", color);
        }
    }
}
