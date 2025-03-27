using UnityEngine;

public class WaterController : MonoBehaviour
{
    private Material waterMaterial;
    private Camera mainCamera;

    void Start()
    {
        // 获取渲染器的材质
        Renderer rend = GetComponent<Renderer>();
        if (rend != null)
        {
            waterMaterial = rend.material;
        }

        mainCamera = Camera.main;
    }

    void Update()
    {
        if (waterMaterial != null)
        {
            // 传递鼠标位置到着色器
            Vector4 mousePos = new Vector4(Input.mousePosition.x, Input.mousePosition.y, 0, 0);
            waterMaterial.SetVector("_MousePos", mousePos);
        }
    }
}