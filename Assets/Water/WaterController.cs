using UnityEngine;

public class WaterController : MonoBehaviour
{
    private Material waterMaterial;
    private Camera mainCamera;

    void Start()
    {
        // ��ȡ��Ⱦ���Ĳ���
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
            // �������λ�õ���ɫ��
            Vector4 mousePos = new Vector4(Input.mousePosition.x, Input.mousePosition.y, 0, 0);
            waterMaterial.SetVector("_MousePos", mousePos);
        }
    }
}