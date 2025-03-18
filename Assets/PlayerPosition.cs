using UnityEngine;

public class PlayerShaderController : MonoBehaviour
{
    public Transform player; 
    public Material material;

    void Update()
    {
        if (material != null && player != null)
        {
            material.SetVector("_PlayerPosition", player.position);
        }
    }
}