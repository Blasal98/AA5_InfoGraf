using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoidsManager : MonoBehaviour
{
    public GameObject gaviotaPrefab;
    public GameObject gaviotaTarget;
    public int gaviotaCount = 20;

    public float gaviotaMinSpeed = 1;
    public float gaviotaMaxSpeed = 5;

    public float gaviotaFlockingForce = 4;
    public float gaviotaTargetForce = 8;
    public float gaviotaAvoidanceForce = 20;

    [HideInInspector] public List<GameObject> gaviotaList;
    [HideInInspector] public List<Vector3> gaviotaVelocityList;

    public ComputeShader shader;
    [HideInInspector] public ComputeBuffer shaderBuffer;
    [HideInInspector] public GameObjectInfo[] shaderData;

    public bool collisionWithMountain = false;

    public struct GameObjectInfo
    {
        public Vector3 position;
        public Vector3 velocity;

        public Vector3 separation;
        public Vector3 cohesion;
        public Vector3 alignment;

        public static int GetStructSize()
        {
            //Los vec3 son 3 floats, pues neceistamos el total de floats en la struct
            return sizeof(float) * 15;
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
            shaderData[i].velocity = Vector3.zero;
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
            float rayLength = 3.5f;
            Ray ray = new Ray(gaviotaList[i].transform.position, Vector3.Normalize(gaviotaVelocityList[i])); ;
            RaycastHit[] hits = Physics.RaycastAll(ray, rayLength);

            Vector3 mountainNormal = Vector3.zero;
            bool mountainCollision = false;
            for (int j = 0; j < hits.Length; j++)
            {
                if (hits[j].transform.name == "mountains")
                {
                    Debug.DrawRay(ray.origin, ray.direction * rayLength, Color.red);
                    mountainNormal = hits[j].normal;
                    mountainCollision = true;
                    break;
                }
            }

            

            Vector3 acceleration = Vector3.zero;

            if (mountainCollision && collisionWithMountain)
            {
                acceleration = /*mountainNormal * 20 + */Vector3.up * gaviotaAvoidanceForce;
            }
            else
            {

                Vector3 separation = shaderData[i].separation;
                Vector3 cohesion = shaderData[i].cohesion;
                Vector3 alignment = shaderData[i].alignment;

                Vector3 targetDirection = Vector3.Normalize(gaviotaTarget.transform.position - gaviotaList[i].transform.position);
                Vector3 flockingForce = Vector3.Normalize(separation * 20 + cohesion * 10 + alignment * 1) * gaviotaFlockingForce;
                Vector3 targetForce = targetDirection * gaviotaTargetForce;

                acceleration = flockingForce + targetForce;

            }

            //euler
            //vel += acc * time
            //pos += vel * time

            gaviotaVelocityList[i] += acceleration * Time.deltaTime;
            float speed = gaviotaVelocityList[i].magnitude;
            speed = Mathf.Clamp(speed, gaviotaMinSpeed, gaviotaMaxSpeed);
            gaviotaVelocityList[i] = Vector3.Normalize(gaviotaVelocityList[i]) * speed;

            gaviotaList[i].transform.position += gaviotaVelocityList[i] * Time.deltaTime;

            shaderData[i].position = gaviotaList[i].transform.position;
            shaderData[i].velocity = gaviotaVelocityList[i];

            gaviotaList[i].transform.LookAt(gaviotaList[i].transform.position + gaviotaVelocityList[i]);

        }

        shaderBuffer.SetData(shaderData);
    }
}
