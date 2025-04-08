using UnityEngine;

[ExecuteInEditMode]
public class CenterParentByRendererBounds : MonoBehaviour
{
    public bool execute = false;

    void Update()
    {
        if (!execute) return;
        execute = false;

        // 获取所有子物体上的 Renderer
        Renderer[] renderers = GetComponentsInChildren<Renderer>();
        if (renderers.Length == 0)
        {
            Debug.LogWarning("找不到任何 Renderer，无法计算包围盒。");
            return;
        }

        // 用第一个 Renderer 初始化 Bounds
        Bounds totalBounds = renderers[0].bounds;
        // 把其他 Renderer 的范围都包起来
        for (int i = 1; i < renderers.Length; i++)
        {
            totalBounds.Encapsulate(renderers[i].bounds);
        }

        // 计算模型“可见范围”的中心
        Vector3 desiredCenter = totalBounds.center;
        Vector3 offset = desiredCenter - transform.position;

        // 先移动父物体到可见中心
        transform.position = desiredCenter;

        // 再让子物体反向移动 offset，保证它们在世界坐标不变
        foreach (Transform child in transform)
        {
            child.position -= offset;
        }

        Debug.Log("已根据所有子物体Renderer包围盒，居中父物体 pivot。");
    }
}
