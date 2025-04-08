using UnityEngine;
using UnityEditor;

public class RecenterTerrain : MonoBehaviour
{
    [MenuItem("Tools/Recenter terrain1 To World Origin")]
    static void Recenter()
    {
        GameObject terrain = GameObject.Find("terrain1");
        if (terrain == null)
        {
            Debug.LogError("找不到名为 terrain1 的对象！");
            return;
        }

        Vector3 offset = terrain.transform.position;

        Undo.RegisterFullObjectHierarchyUndo(terrain, "Recenter terrain1");

        foreach (Transform child in terrain.transform)
        {
            child.position += offset;
        }

        terrain.transform.position = Vector3.zero;

        Debug.Log("已将 terrain1 移动到原点，并保留了所有子物体的世界位置。");
    }
}
