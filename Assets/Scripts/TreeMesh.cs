using UnityEngine;
[ExecuteAlways]
public class ReplaceMeshesInEditor : MonoBehaviour
{
    public Mesh newMesh;

    private void OnEnable()
    {
        ReplaceAllMeshes();
    }

    private void ReplaceAllMeshes()
    {
        if (newMesh == null)
            return;

        // 获取自己和所有子孙物体上的 MeshFilter
        MeshFilter[] filters = GetComponentsInChildren<MeshFilter>(true);

        foreach (MeshFilter mf in filters)
        {
            mf.sharedMesh = newMesh;
        }
    }
}
