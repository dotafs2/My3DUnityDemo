using UnityEngine;

public class PlayerPositionToShader : MonoBehaviour
{
    public Transform player; 
    public Material material; 

    void Update()
    {
        if (player != null && material != null)
        {
            Vector3 pos = player.position;
            material.SetVector("_PlayerPosition", pos);
        }
    }
}
