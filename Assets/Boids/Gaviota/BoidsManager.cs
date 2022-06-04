using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoidsManager : MonoBehaviour
{
    public GameObject gaviotaPrefab;
    public GameObject gaviotaTarget;
    public int gaviotaCount = 20;
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
            for (int j = 0; j < gaviotaCount; j++)
            {
                GameObject gaviota = Instantiate(gaviotaPrefab, this.transform);
                gaviota.transform.position = new Vector3(
                    this.transform.position.x + i * 2.0f, 
                    this.transform.position.y,
                    this.transform.position.z + j * 2.0f);
                gaviotaList.Add(gaviota);
                gaviotaVelocityList.Add(Vector3.zero);
            }
        }

        shaderData = new GameObjectInfo[gaviotaList.Count];
        shaderBuffer = new ComputeBuffer(gaviotaList.Count, GameObjectInfo.GetStructSize());

        for (int i = 0; i < gaviotaList.Count; i++)
        {
            shaderData[i].position = gaviotaList[i].transform.position;
            gaviotaVelocityList[i] = Vector3.zero;
        }

        shaderBuffer.SetData(shaderData);

    }

    // Update is called once per frame
    void Update()
    {
        int kernelHandle = shader.FindKernel("CSMain");

        shader.SetBuffer(kernelHandle, "BoidsResult", shaderBuffer);
        shader.SetInt("boidCount", gaviotaList.Count);

        //cada 128 gaviotas necesitamos un threadgroup mas
        int threadGroups = Mathf.CeilToInt(gaviotaList.Count / 128.0f);

        shader.Dispatch(kernelHandle, threadGroups, 1, 1);
        shaderBuffer.GetData(shaderData);

        //Por cada gaviota aplicaremos euler
        for(int i = 0; i < gaviotaList.Count; i++)
        {
            //euler
            //vel += acc * time
            //pos += vel * time

            Vector3 targetDirection = Vector3.Normalize(gaviotaTarget.transform.position - gaviotaList[i].transform.position);

            Vector3 separation = shaderData[i].separation;
            Vector3 cohesion = shaderData[i].cohesion;
            Vector3 alignment = shaderData[i].alignment;

            Vector3 acceleration = (separation * 2 + cohesion * 2 + alignment) * 0.2f + targetDirection * 0.8f ;

            gaviotaVelocityList[i] += acceleration * Time.deltaTime;
            gaviotaVelocityList[i].Normalize();

            gaviotaList[i].transform.position += gaviotaVelocityList[i] * Time.deltaTime;
            shaderData[i].position = gaviotaList[i].transform.position;
            gaviotaList[i].transform.LookAt(gaviotaList[i].transform.position + gaviotaVelocityList[i]);

            
        }

        shaderBuffer.SetData(shaderData);
    }
}
