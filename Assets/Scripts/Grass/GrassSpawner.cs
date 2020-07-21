using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassSpawner : MonoBehaviour
{

    public GameObject GrassModel;
    public Material GrassMat;
    public Vector2 GrassSize;
    public float Count;

    private MeshFilter meshFilter;



    public void Start()
    {
        meshFilter = gameObject.AddComponent<MeshFilter>();
        for (int i = 0; i < Count; i++)
        {

            InitializeGrass();
        }
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
        Collider[] c = Physics.OverlapSphere(pos, Random.Range(1.0f,2.0f));
        for (int i = 0; i < c.Length; i++)
        {
            if (c[i].gameObject.name != "Plane")
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


    void InitializeGrass()
    {
        int tempGrassNumW = Mathf.FloorToInt(GrassSize.x);
        int tempGrassNumL = Mathf.FloorToInt(GrassSize.y);

        List<Vector3> tempGrassPosList = new List<Vector3>();
        List<GameObject> temgGrassObjList = new List<GameObject>();

        CombineInstance[] combine = new CombineInstance[tempGrassNumW * tempGrassNumL];

        int tmpIndex = 0;

        for (int w = 0; w < tempGrassNumW; w++)
        {
            for (int l = 0; l < tempGrassNumL; l++)
            {

                GameObject tmpGo = SpawnGrass(new Vector3(
                    Random.Range(1.0f, 19.0f),
                    transform.position.y,
                    Random.Range(1.0f, 19.0f)));
                if (tmpGo == null)
                {
                    continue;
                }
                temgGrassObjList.Add(tmpGo);

                //    Tool_Spawn.SpawnObj(
                //    true, grassModel, gameObject, "Grass_" + (w + l * tempGrassNumW).ToString(),
                //    tempGrassPosList[w + l * tempGrassNumW], new Vector3(0, UnityEngine.Random.Range(0, 360), 0), false
                //);
                //temgGrassObjList[w + l * tempGrassNumW].transform.localScale = new Vector3(1, UnityEngine.Random.Range(0.7f, 1.3f) * grassHeight, grassSize);

                MeshFilter tmpMeshfilter = temgGrassObjList[tmpIndex].GetComponent<MeshFilter>() as MeshFilter;
                combine[tmpIndex].mesh = tmpMeshfilter.sharedMesh;
                combine[tmpIndex].transform = temgGrassObjList[tmpIndex].transform.localToWorldMatrix;
                temgGrassObjList[tmpIndex].SetActive(false);

                tmpIndex++;
            }
        }


        GameObject go = new GameObject();
        MeshFilter mf = go.AddComponent<MeshFilter>();
        mf.mesh = new Mesh();

        CombineInstance[] exist = new CombineInstance[tmpIndex];
        for (int i = 0; i < combine.Length; i++)
        {
            if (combine[i].mesh != null)
            {
                exist[i] = combine[i];
            }
        }
        mf.mesh.CombineMeshes(exist);
        go.AddComponent<MeshRenderer>().sharedMaterial = GrassMat;
        //meshFilter.mesh = new Mesh();
        //meshFilter.mesh.CombineMeshes(combine);
        //gameObject.AddComponent<MeshRenderer>().material = GrassMat;
        for (int n = 0; n < tmpIndex; n++)
        {
            Destroy(temgGrassObjList[n]);
        }
    }

}
