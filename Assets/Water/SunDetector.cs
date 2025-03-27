using UnityEngine;

public class OceanController : MonoBehaviour
{
    public Transform sunTransform; // 指向代表太阳的游戏对象
    public float sunIntensity = 210.0f;

    private Material waterMaterial;

    void Start()
    {
        // 获取水面材质
        Renderer renderer = GetComponent<Renderer>();
        waterMaterial = renderer.material;
    }

    void Update()
    {
        if (waterMaterial != null && sunTransform != null)
        {
            // 更新太阳方向
            waterMaterial.SetVector("_SunDirection", sunTransform.forward);

            // 更新太阳亮度
            waterMaterial.SetFloat("_SunIntensity", sunIntensity);
        }
    }
}