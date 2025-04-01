using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FrameSetting : MonoBehaviour
{
    public int targetFrameRate = 165;

    private void Awake()
    {
        Application.targetFrameRate = targetFrameRate;
    }
}