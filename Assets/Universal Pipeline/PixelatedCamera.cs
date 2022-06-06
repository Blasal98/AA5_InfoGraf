using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PixelatedCamera : MonoBehaviour
{

    public Camera mainCamera;
    Vector3 originalPosition;
    public Material pixelatedMat;

    // Start is called before the first frame update
    void Start()
    {
        originalPosition = mainCamera.transform.position;
    }

    // Update is called once per frame
    void Update()
    {
        pixelatedMat.SetFloat("PixelSize", Mathf.Lerp(2000,10, Mathf.InverseLerp(0,20,Vector3.Distance(transform.position,originalPosition))));
    }
}
