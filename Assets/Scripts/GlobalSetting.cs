using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class GlobalSetting : MonoBehaviour
{
    const string posArrayCountName = "_PositionArrayCount";
    const string posArrayName = "_ObstaclePositions";
    public Transform[] Creatures;
    public Vector4[] obstaclePositions = new Vector4[100];


    [Header("贴图有关")]
    //public Texture2DArray array;
    public List<Texture2D> AlbedoTextures;
    public List<Texture2D> NormalTextures;
    public Texture BlendTexture;
    //public Texture BlendHeightTexture;
    public Texture BlendNormalTexture;

    [Space(10)]
    [Header("贴图具体参数")]
    [Range(0, 20f)]
    public float WorldScale = 0.1f;
    [Range(0, 20f)]
    public float MScale = 0.1f;
    [Range(0, 20f)]
    public float RScale = 0.1f;
    [Range(0, 20f)]
    public float GScale = 0.1f;
    [Range(0, 20f)]
    public float BScale = 0.1f;


    public float MBumpScale = 1f;

    public float RBumpScale = 1f;

    public float GBumpScale = 1f;

    public float BBumpScale = 1f;

    //public float ParallaxStrength = 0.01f;
    [Range(0, 20)]
    public float BlendNormalBumpScale = 1;

    [Range(0, 15)]
    public float BlendGroundValue = 1;

    public Color MColor = Color.white;
    public Color RColor = Color.white;
    public Color GColor = Color.white;
    public Color BColor = Color.white;

    public ECopyTexMethpd copyTexMethod;

    public Texture2DArray albedoArray;
    public Texture2DArray normalArray;

    public enum ECopyTexMethpd
    {
        CopyTexture = 0,                                 // 使用 Graphics.CopyTexture 方法 //
        SetPexels = 1,                                      // 使用 Texture2DArray.SetPixels 方法 //
    }


    void FixedUpdate()
    {
        // 刷新所有的碰撞物体位置与数量
        Shader.SetGlobalFloat(posArrayCountName, Creatures.Length);
        for (int i = 0; i < Creatures.Length; i++)
        {
            obstaclePositions[i] = Creatures[i].position;
        }
        Shader.SetGlobalVectorArray(posArrayName, obstaclePositions);

        SetUpdateValue();
    }

    void Start()// 注:测试用所以放在 FixedUpdate 实际上只要在Start执行一次
    {


        //AlbedoTextures[i].
        albedoArray = new Texture2DArray(1024, 1024, AlbedoTextures.Count, TextureFormat.RGBA32, true, false);
        normalArray = new Texture2DArray(1024, 1024, NormalTextures.Count, TextureFormat.RGBA32, true, true);



        for (int i = 0; i < AlbedoTextures.Count; i++)
        {
            // 以下两行都可以 //
            //texArr.SetPixels(textures[i].GetPixels(), i);
            albedoArray.SetPixels(AlbedoTextures[i].GetPixels(), i, 0);
        }

        albedoArray.Apply();



        for (int i = 0; i < NormalTextures.Count; i++)
        {
            // 以下两行都可以 //
            //texArr.SetPixels(textures[i].GetPixels(), i);
            normalArray.SetPixels(NormalTextures[i].GetPixels(), i,0);
        }

        normalArray.Apply();



    }

    void SetUpdateValue()
    {
        Shader.SetGlobalTexture("_BlendTex", BlendTexture);
        Shader.SetGlobalTexture("_BlendNormalMap", BlendNormalTexture);
        //Shader.SetGlobalTexture("_ParallaxMap", BlendHeightTexture);


        Shader.SetGlobalFloat("_WorldScale", WorldScale);
        Shader.SetGlobalFloat("_BlendNormalBumpScale", BlendNormalBumpScale);
        //Shader.SetGlobalFloat("_ParallaxStrength", ParallaxStrength);
        Shader.SetGlobalFloat("_MScale", MScale);
        Shader.SetGlobalFloat("_RScale", RScale);
        Shader.SetGlobalFloat("_GScale", GScale);
        Shader.SetGlobalFloat("_BScale", BScale);

        Shader.SetGlobalColor("_TintM", MColor);
        Shader.SetGlobalColor("_TintR", RColor);
        Shader.SetGlobalColor("_TintG", GColor);
        Shader.SetGlobalColor("_TintB", BColor);

        Shader.SetGlobalFloat("_MBumpScale", MBumpScale);
        Shader.SetGlobalFloat("_RBumpScale", RBumpScale);
        Shader.SetGlobalFloat("_GBumpScale", GBumpScale);
        Shader.SetGlobalFloat("_BBumpScale", BBumpScale);
        Shader.SetGlobalFloat("_BlendValue", BlendGroundValue);
        Shader.SetGlobalTexture("_MapArray", albedoArray);
        Shader.SetGlobalTexture("_NormalArray", normalArray);
    }

    //[MenuItem("Tools/Generate Texture2DArray")]
    //private void CreateTexArray(List<Texture2D> sourceTextures)
    //{
    //    if (sourceTextures.Count == 0)
    //    {
    //        return;
    //    }

    //    //Create texture2DArray
    //    Texture2DArray texture2DArray = new Texture2DArray(sourceTextures[0].width,
    //        sourceTextures[0].height, sourceTextures.Count, sourceTextures[0].format, true,false);
    //    // Apply settings
    //    texture2DArray.filterMode = FilterMode.Bilinear;
    //    texture2DArray.wrapMode = TextureWrapMode.Repeat;

    //    for (int i = 0; i < sourceTextures.Count; i++)
    //    {
    //        texture2DArray.SetPixels(sourceTextures[i].GetPixels(), i, 0);
    //    }

    //    // Apply our changes
    //    texture2DArray.Apply(false);

    //    //Save 
    //    AssetDatabase.CreateAsset(texture2DArray, "Assets/TexArray.asset");
    //}
}
