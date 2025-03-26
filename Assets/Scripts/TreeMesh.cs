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

        // ��ȡ�Լ����������������ϵ� MeshFilter
        MeshFilter[] filters = GetComponentsInChildren<MeshFilter>(true);

        foreach (MeshFilter mf in filters)
        {
            mf.sharedMesh = newMesh;
        }
    }
}
