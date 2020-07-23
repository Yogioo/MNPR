using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class GrassSpawner : MonoBehaviour
{

    public GameObject GrassModel;
    public Material GrassMat;

    [Header("需要生成多少个草")]
    public uint InitGrassCount;
    [Header("草密度")]
    [Range(1, 10)]
    public float GrassDensity;



    public void Start()
    {
        InitGrassForRoom();
        //meshFilter = gameObject.AddComponent<MeshFilter>();
        //InitializeGrass();
    }


    public void Update()
    {
        //int index = 0;
        //for (int i = 0; i < GrassSize.x; i++)
        //{
        //    for (int j = 0; j < GrassSize.y; j++)
        //    {
        //        GrassArray[index].transform.position = new Vector3(i, 0, j) * Gap;
        //        index++;
        //    }
        //}
    }
    public GameObject SpawnGrass(Vector3 pos)
    {
        Collider[] c = Physics.OverlapSphere(pos, Random.Range(1.0f, 2.0f));
        for (int i = 0; i < c.Length; i++)
        {
            if (c[i].gameObject.name != transform.name)
            {
                return null;
            }
        }
        // Debug.Log(Physics.OverlapSphere(pos, 1));
        GameObject m = GameObject.Instantiate(GrassModel, transform);
        m.transform.position = pos;
        m.transform.eulerAngles += new Vector3(0, Random.Range(0, 360), 0);
        m.GetComponent<Renderer>().sharedMaterial = GrassMat;

        return m;
    }

    void InitGrassForRoom()
    {
        GameObject GrassGroup = new GameObject("Room Grass Group");
        List<GameObject> InitTemp = new List<GameObject>();
        uint limitCount = InitGrassCount + 300;
        for (int i = 0; i < InitGrassCount; i++)
        {
            limitCount--;
            if (limitCount < 0)
            {
                return;
            }
            Vector3 targetPos = new Vector3(Random.Range(-GrassDensity, GrassDensity), 0, Random.Range(-GrassDensity, GrassDensity));
            targetPos += transform.position;

            Collider[] c = Physics.OverlapSphere(targetPos, Random.Range(1.0f, 2.0f));

            for (int y = 0; y < c.Length; y++)
            {
                if (c[y].gameObject.name != transform.name)
                {
                    continue;
                }
            }

            GameObject m = GameObject.Instantiate(GrassModel, GrassGroup.transform);
            InitTemp.Add(m);
            m.transform.position = targetPos;
            m.transform.eulerAngles += new Vector3(0, Random.Range(0, 360), 0);

        }


        CombineInstance[] combine = new CombineInstance[InitTemp.Count];
        for (int i = 0; i < InitTemp.Count; i++)
        {
            MeshFilter tmpMeshfilter = InitTemp[i].GetComponent<MeshFilter>();
            combine[i].mesh = tmpMeshfilter.sharedMesh;
            combine[i].transform = tmpMeshfilter.transform.localToWorldMatrix;
            tmpMeshfilter.gameObject.SetActive(false);
        }
        MeshFilter groupMF = GrassGroup.AddComponent<MeshFilter>();
        groupMF.mesh = new Mesh();
        groupMF.mesh.CombineMeshes(combine);
        GrassGroup.AddComponent<MeshRenderer>().sharedMaterial = GrassMat;

        for (int i = 0; i < InitTemp.Count; i++)
        {
            Destroy(InitTemp[i]);
        }
        GrassGroup.transform.SetParent(transform);
    }

    //void InitializeGrass()
    //{
    //    int tempGrassNumW = Mathf.FloorToInt(GrassSize.x);
    //    int tempGrassNumL = Mathf.FloorToInt(GrassSize.y);

    //    List<Vector3> tempGrassPosList = new List<Vector3>();
    //    List<GameObject> temgGrassObjList = new List<GameObject>();

    //    CombineInstance[] combine = new CombineInstance[tempGrassNumW * tempGrassNumL];

    //    int tmpIndex = 0;

    //    for (int w = 0; w < tempGrassNumW; w++)
    //    {
    //        for (int l = 0; l < tempGrassNumL; l++)
    //        {

    //            GameObject tmpGo = SpawnGrass(new Vector3(
    //                Random.Range(transform.position.x - 10, transform.position.x + 10),
    //                transform.position.y,
    //                Random.Range(transform.position.z - 10, transform.position.z + 10)));
    //            if (tmpGo == null)
    //            {
    //                continue;
    //            }
    //            temgGrassObjList.Add(tmpGo);

    //            MeshFilter tmpMeshfilter = temgGrassObjList[tmpIndex].GetComponent<MeshFilter>() as MeshFilter;
    //            combine[tmpIndex].mesh = tmpMeshfilter.sharedMesh;
    //            combine[tmpIndex].transform = temgGrassObjList[tmpIndex].transform.localToWorldMatrix;
    //            temgGrassObjList[tmpIndex].SetActive(false);

    //            tmpIndex++;
    //        }
    //    }


    //    GameObject go = new GameObject();
    //    MeshFilter mf = go.AddComponent<MeshFilter>();
    //    mf.mesh = new Mesh();

    //    CombineInstance[] exist = new CombineInstance[tmpIndex];
    //    for (int i = 0; i < combine.Length; i++)
    //    {
    //        if (combine[i].mesh != null)
    //        {
    //            exist[i] = combine[i];
    //        }
    //    }
    //    mf.mesh.CombineMeshes(exist);
    //    go.AddComponent<MeshRenderer>().sharedMaterial = GrassMat;
    //    //meshFilter.mesh = new Mesh();
    //    //meshFilter.mesh.CombineMeshes(combine);
    //    //gameObject.AddComponent<MeshRenderer>().material = GrassMat;
    //    for (int n = 0; n < tmpIndex; n++)
    //    {
    //        Destroy(temgGrassObjList[n]);
    //    }
    //}

}
