using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GlobalSetting : MonoBehaviour
{
    const string posArrayCountName = "_PositionArrayCount";
    const string posArrayName = "_ObstaclePositions";
    public Transform[] Creatures;
    public Vector4[] obstaclePositions = new Vector4[100];


    void FixedUpdate()
    {
        Shader.SetGlobalFloat(posArrayCountName, Creatures.Length);
        for (int i = 0; i < Creatures.Length; i++)
        {
            obstaclePositions[i] = Creatures[i].position;
        }
        Shader.SetGlobalVectorArray(posArrayName, obstaclePositions);
    }
}
