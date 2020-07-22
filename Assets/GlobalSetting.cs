using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GlobalSetting : MonoBehaviour
{
    const string posArrayCountName = "_PositionArrayCount";
    const string posArrayName = "_ObstaclePositions";
    public Transform[] Creatures;
    public Vector4[] obstaclePositions = new Vector4[100];


    [Header("贴图有关")]
    public List<Texture> AlbedoTextures;
    public List<Texture> NormalTextures;
    public Texture BlendTexture;
    public Texture BlendHeightTexture;
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

    public float ParallaxStrength = 0.01f;
    [Range(0,20)]
    public float BlendNormalBumpScale = 1;

    public Color MColor = Color.white;
    public Color RColor = Color.white;
    public Color GColor = Color.white;
    public Color BColor = Color.white;


    void FixedUpdate()
    {
        // 刷新所有的碰撞物体位置与数量
        Shader.SetGlobalFloat(posArrayCountName, Creatures.Length);
        for (int i = 0; i < Creatures.Length; i++)
        {
            obstaclePositions[i] = Creatures[i].position;
        }
        Shader.SetGlobalVectorArray(posArrayName, obstaclePositions);

        SetMapShader();
    }

    void SetMapShader()// 注:测试用所以放在 FixedUpdate 实际上只要在Start执行一次
    {
        Shader.SetGlobalTexture("_MapM", AlbedoTextures[0]);
        Shader.SetGlobalTexture("_MapR", AlbedoTextures[1]);
        Shader.SetGlobalTexture("_MapG", AlbedoTextures[2]);
        Shader.SetGlobalTexture("_MapB", AlbedoTextures[3]);

        Shader.SetGlobalTexture("_MNormalMap", NormalTextures[0]);
        Shader.SetGlobalTexture("_RNormalMap", NormalTextures[1]);
        Shader.SetGlobalTexture("_GNormalMap", NormalTextures[2]);
        Shader.SetGlobalTexture("_BNormalMap", NormalTextures[3]);

        Shader.SetGlobalTexture("_BlendTex", BlendTexture); 
        Shader.SetGlobalTexture("_BlendNormalMap", BlendNormalTexture); 
        Shader.SetGlobalTexture("_ParallaxMap", BlendHeightTexture);


        Shader.SetGlobalFloat("_WorldScale", WorldScale);
        Shader.SetGlobalFloat("_BlendNormalBumpScale", BlendNormalBumpScale);
        Shader.SetGlobalFloat("_ParallaxStrength", ParallaxStrength);
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
    }
}
