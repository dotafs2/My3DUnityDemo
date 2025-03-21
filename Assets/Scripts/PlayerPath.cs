using UnityEngine;

public class PlayerFootprintController : MonoBehaviour
{
    [Header("References")]
    public Transform player;                    // 玩家Transform
    public Renderer floorRenderer;              // 地面渲染器

    [Header("Footprint Settings")]
    public float footprintRadius = 1.0f;        // 足迹半径
    public float footprintIntensity = 0.5f;     // 足迹强度

    [Header("Render Texture Settings")]
    public int rtWidth = 1024;                  // 渲染纹理宽度
    public int rtHeight = 1024;                 // 渲染纹理高度

    private Material floorMaterial;             // 地面材质
    private RenderTexture footprintRT;          // 足迹渲染纹理
    private RenderTexture tempRT;               // 临时渲染纹理
    private Material footprintMaterial;         // 用于绘制足迹的材质

    void Start()
    {
        // 获取地面材质
        floorMaterial = floorRenderer.material;

        // 创建用于存储足迹的渲染纹理
        footprintRT = new RenderTexture(rtWidth, rtHeight, 0, RenderTextureFormat.R8);
        footprintRT.Create();

        // 创建临时渲染纹理用于更新足迹
        tempRT = new RenderTexture(rtWidth, rtHeight, 0, RenderTextureFormat.R8);
        tempRT.Create();

        // 创建用于绘制足迹的材质
      //  footprintMaterial = new Material(Shader.Find("Hidden/FootprintUpdater"));

        // 设置shader参数
        floorMaterial.SetTexture("_FootprintMap", footprintRT);
        floorMaterial.SetFloat("_FootprintRadius", footprintRadius);
        floorMaterial.SetFloat("_FootprintIntensity", footprintIntensity);
    }

    void Update()
    {
        // 更新玩家位置参数
        if (player != null)
        {
            floorMaterial.SetVector("_PlayerPos", player.position);
        }

        // 这里可以添加足迹持久化逻辑
        // UpdateFootprintTexture();
    }

    // 如果需要足迹持久化，可以使用此方法
    void UpdateFootprintTexture()
    {
        // 设置绘制足迹的材质参数
        footprintMaterial.SetTexture("_PrevFootprintTex", footprintRT);
        footprintMaterial.SetVector("_PlayerPos", player.position);
        footprintMaterial.SetFloat("_FootprintRadius", footprintRadius);
        footprintMaterial.SetFloat("_FootprintIntensity", footprintIntensity);

        // 绘制到临时RT
        Graphics.Blit(null, tempRT, footprintMaterial);

        // 交换RT
        RenderTexture temp = footprintRT;
        footprintRT = tempRT;
        tempRT = temp;

        // 更新材质中的引用
        floorMaterial.SetTexture("_FootprintMap", footprintRT);
    }

    void OnDestroy()
    {
        // 释放资源
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