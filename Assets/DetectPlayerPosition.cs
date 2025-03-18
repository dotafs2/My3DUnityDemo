using UnityEngine;

public class PlayerPosToShader : MonoBehaviour
{
    public Material targetMaterial; 
    public Transform playerTransform;

    void Update()
    {
        if (targetMaterial != null && playerTransform != null)
        {
            Vector3 playerPos = playerTransform.position;
            targetMaterial.SetVector("_PlayerPos", new Vector4(playerPos.x, playerPos.y, playerPos.z, 1));
        }
    }
}
