using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CheckCulling : MonoBehaviour
{
 
    public GameObject CuliingBox;

    private void OnTriggerEnter(Collider other)
    {
        if(other.gameObject.name== "CullingPanel")
        {
            CuliingBox.SetActive(true);
        }

        if (other.gameObject.name == "HideCullingBox")
        {
            CuliingBox.SetActive(false);
        }
    }
}
