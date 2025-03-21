using UnityEngine;

[ExecuteInEditMode]
public class BloomPostEffect : MonoBehaviour
{
    public Material bloomMaterial;

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        bloomMaterial.SetVector("_Resolution", new Vector4(Screen.width, Screen.height, 0, 0));
        bloomMaterial.SetFloat("_Time", Time.time);

        Graphics.Blit(src, dest, bloomMaterial);
    }
}
