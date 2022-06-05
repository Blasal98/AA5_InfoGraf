using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HumoManager : MonoBehaviour
{
    public Camera mainCamera;
    public GameObject humoPrefab;
    public int humoCount = 100;

    [HideInInspector] public List<GameObject> humoList;

    public ComputeShader shader;
    [HideInInspector] public ComputeBuffer shaderBuffer;
    [HideInInspector] public GameObjectInfo[] shaderData;

    public struct GameObjectInfo
    {
        public Vector3 position;

        public static int GetStructSize()
        {
            //Los vec3 son 3 floats, pues neceistamos el total de floats en la struct
            return sizeof(float) * 3;
        }
    }

    void Start()
    {
        for (int i = 0; i < humoCount; i++) {
            GameObject humo = Instantiate(humoPrefab, this.transform);
            humo.transform.position = this.transform.position;
            humoList.Add(humo);
        }

        shaderData = new GameObjectInfo[humoList.Count];
        shaderBuffer = new ComputeBuffer(humoList.Count, GameObjectInfo.GetStructSize());

        for (int i = 0; i < humoList.Count; i++)
        {
            shaderData[i].position = humoList[i].transform.position;
        }

        shaderBuffer.SetData(shaderData);
    }

    void Update()
    {
        int kernelHandle = shader.FindKernel("CSHumo");

        shader.SetBuffer(kernelHandle, "BoidsResult", shaderBuffer);
        shader.SetInt("boidCount", humoList.Count);

        //cada 128 gaviotas necesitamos un threadgroup mas
        int threadGroups = Mathf.CeilToInt(humoList.Count / 128.0f);

        shader.Dispatch(kernelHandle, threadGroups, 1, 1);
        shaderBuffer.GetData(shaderData);

        for (int i = 0; i < humoList.Count; i++)
        {
            humoList[i].transform.position = shaderData[i].position;

            humoList[i].transform.LookAt(mainCamera.transform.position);
            humoList[i].transform.Rotate(new Vector3(90, 0, 0), Space.Self);
        }
    }
}
