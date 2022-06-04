using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoidsManager : MonoBehaviour
{
    public GameObject gaviotaPrefab;
    public int gaviotaCount = 10;
    [HideInInspector] public List<GameObject> gaviotaList;
    [HideInInspector] public List<Vector3> gaviotaVelocityList;

    public ComputeShader shader;
    [HideInInspector] public ComputeBuffer shaderBuffer;
    [HideInInspector] public GameObjectInfo[] shaderData;

    public struct GameObjectInfo
    {
        public Vector3 position;

        public Vector3 velocity;
        public float speed;

        public Vector3 separation;
        public Vector3 cohesion;
        public Vector3 alignment;

        public static int GetStructSize()
        {
            //Los vec3 son 3 floats, pues neceistamos el total de floats en la struct
            return sizeof(float) * 16;
        }
    }

    void Start()
    {
        for(int i = 0; i < gaviotaCount; i++)
        {
            GameObject gaviota = Instantiate(gaviotaPrefab, this.transform);
            gaviota.transform.position = new Vector3(this.transform.position.x * i * 1.25f, this.transform.position.y, this.transform.position.z);
            gaviotaList.Add(gaviota);
            gaviotaVelocityList.Add(Vector3.zero);
        }

        shaderData = new GameObjectInfo[gaviotaList.Count];
        shaderBuffer = new ComputeBuffer(gaviotaList.Count, GameObjectInfo.GetStructSize());
        shaderBuffer.SetData(shaderData);

    }

    // Update is called once per frame
    void Update()
    {
        int kernelHandle = shader.FindKernel("CSMain");

        shader.SetBuffer(kernelHandle, "BoidsResult", shaderBuffer);
        //shader.SetFloat("deltaTime", Time.deltaTime);

        int threadGroups = Mathf.CeilToInt(gaviotaList.Count / 128.0f);
        shader.Dispatch(kernelHandle, threadGroups, 1, 1);

        shaderBuffer.GetData(shaderData);

        //Por cada gaviota aplicaremos euler
        for(int i = 0; i < gaviotaList.Count; i++)
        {
            //euler
            //vel += acc * time
            //pos += vel * time

            Vector3 separation = shaderData[i].separation;
            Vector3 cohesion = shaderData[i].cohesion;
            Vector3 alignment = shaderData[i].alignment;

            Vector3 acceleration = separation + cohesion + alignment;
            gaviotaVelocityList[i] += acceleration * Time.deltaTime;
            gaviotaList[i].transform.position += gaviotaVelocityList[i] * Time.deltaTime;

            
        }
    }
}
