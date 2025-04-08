using UnityEngine;
using System.Collections.Generic;

public class RuntimeFadeBelowY : MonoBehaviour
{
    [Header("低于该 Y 值开始渐隐")]
    public float fadeThresholdY = 0f;

    [Header("渐隐速度（越大越快）")]
    public float fadeSpeed = 1f;

    private List<Renderer> childRenderers = new List<Renderer>();
    private Dictionary<Renderer, float> originalAlphas = new Dictionary<Renderer, float>();

    void Start()
    {
        Renderer[] renderers = GetComponentsInChildren<Renderer>();

        foreach (var rend in renderers)
        {
            if (!rend.material.HasProperty("_BaseColor"))
                continue;

            // 克隆材质，防止修改原始资源
            Material cloned = new Material(rend.material);

            // 设置为透明材质（URP Lit）
            cloned.SetFloat("_Surface", 1); // 1 = Transparent
            cloned.SetFloat("_Blend", 0);   // 0 = Alpha
            cloned.SetFloat("_ZWrite", 0);  // 禁止写入深度缓冲
            cloned.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");

            // 设置渲染队列
            cloned.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;

            // 设置初始颜色 alpha = 1
            Color baseColor = cloned.GetColor("_BaseColor");
            baseColor.a = 1.0f;
            cloned.SetColor("_BaseColor", baseColor);

            rend.material = cloned;

            // 记录原始 alpha
            childRenderers.Add(rend);
            originalAlphas[rend] = baseColor.a;
        }
    }

    void Update()
    {
        foreach (var rend in childRenderers)
        {
            if (rend == null || !rend.material.HasProperty("_BaseColor")) continue;

            float currentY = rend.transform.position.y;
            float targetAlpha = currentY < fadeThresholdY ? 0f : originalAlphas[rend];

            Color c = rend.material.GetColor("_BaseColor");
            c.a = Mathf.MoveTowards(c.a, targetAlpha, fadeSpeed * Time.deltaTime);
            rend.material.SetColor("_BaseColor", c);
        }
    }
}
