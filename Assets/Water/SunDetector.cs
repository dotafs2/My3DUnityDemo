using UnityEngine;

public class OceanController : MonoBehaviour
{
    public Transform sunTransform; // ָ�����̫������Ϸ����
    public float sunIntensity = 210.0f;

    private Material waterMaterial;

    void Start()
    {
        // ��ȡˮ�����
        Renderer renderer = GetComponent<Renderer>();
        waterMaterial = renderer.material;
    }

    void Update()
    {
        if (waterMaterial != null && sunTransform != null)
        {
            // ����̫������
            waterMaterial.SetVector("_SunDirection", sunTransform.forward);

            // ����̫������
            waterMaterial.SetFloat("_SunIntensity", sunIntensity);
        }
    }
}