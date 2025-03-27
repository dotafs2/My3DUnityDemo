using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class VolumetricCloudsManager : MonoBehaviour
{
    public static VolumetricCloudsManager instance;

    public Light directionalLight;
    public List<MeshRenderer> cloudMeshRenderer;

    public void OnEnable()
    {
        instance = this;
    }
}