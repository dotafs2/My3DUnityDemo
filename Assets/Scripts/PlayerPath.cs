using UnityEngine;

public class PlayerFootprintController : MonoBehaviour
{
    [Header("References")]
    public Transform player;                    // ���Transform
    public Renderer floorRenderer;              // ������Ⱦ��

    [Header("Footprint Settings")]
    public float footprintRadius = 1.0f;        // �㼣�뾶
    public float footprintIntensity = 0.5f;     // �㼣ǿ��

    [Header("Render Texture Settings")]
    public int rtWidth = 1024;                  // ��Ⱦ������
    public int rtHeight = 1024;                 // ��Ⱦ����߶�

    private Material floorMaterial;             // �������
    private RenderTexture footprintRT;          // �㼣��Ⱦ����
    private RenderTexture tempRT;               // ��ʱ��Ⱦ����
    private Material footprintMaterial;         // ���ڻ����㼣�Ĳ���

    void Start()
    {
        // ��ȡ�������
        floorMaterial = floorRenderer.material;

        // �������ڴ洢�㼣����Ⱦ����
        footprintRT = new RenderTexture(rtWidth, rtHeight, 0, RenderTextureFormat.R8);
        footprintRT.Create();

        // ������ʱ��Ⱦ�������ڸ����㼣
        tempRT = new RenderTexture(rtWidth, rtHeight, 0, RenderTextureFormat.R8);
        tempRT.Create();

        // �������ڻ����㼣�Ĳ���
      //  footprintMaterial = new Material(Shader.Find("Hidden/FootprintUpdater"));

        // ����shader����
        floorMaterial.SetTexture("_FootprintMap", footprintRT);
        floorMaterial.SetFloat("_FootprintRadius", footprintRadius);
        floorMaterial.SetFloat("_FootprintIntensity", footprintIntensity);
    }

    void Update()
    {
        // �������λ�ò���
        if (player != null)
        {
            floorMaterial.SetVector("_PlayerPos", player.position);
        }

        // �����������㼣�־û��߼�
        // UpdateFootprintTexture();
    }

    // �����Ҫ�㼣�־û�������ʹ�ô˷���
    void UpdateFootprintTexture()
    {
        // ���û����㼣�Ĳ��ʲ���
        footprintMaterial.SetTexture("_PrevFootprintTex", footprintRT);
        footprintMaterial.SetVector("_PlayerPos", player.position);
        footprintMaterial.SetFloat("_FootprintRadius", footprintRadius);
        footprintMaterial.SetFloat("_FootprintIntensity", footprintIntensity);

        // ���Ƶ���ʱRT
        Graphics.Blit(null, tempRT, footprintMaterial);

        // ����RT
        RenderTexture temp = footprintRT;
        footprintRT = tempRT;
        tempRT = temp;

        // ���²����е�����
        floorMaterial.SetTexture("_FootprintMap", footprintRT);
    }

    void OnDestroy()
    {
        // �ͷ���Դ
        if (footprintRT != null)
        {
            footprintRT.Release();
            Destroy(footprintRT);
        }

        if (tempRT != null)
        {
            tempRT.Release();
            Destroy(tempRT);
        }

        if (footprintMaterial != null)
        {
            Destroy(footprintMaterial);
        }
    }
}