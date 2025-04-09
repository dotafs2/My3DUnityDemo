using UnityEngine;

public class RoadAppearOnApproach : MonoBehaviour
{
    public Transform targetPosition; // 设置目标位置的空物体
    public float moveSpeed = 2f;
    private bool playerNearby = false;

    void Update()
    {
        if (playerNearby)
        {
            Debug.Log("当前坐标: " + transform.position + " → 目标坐标: " + targetPosition.position);
            transform.position = Vector3.MoveTowards(transform.position, targetPosition.position, moveSpeed * Time.deltaTime);
        }
    }


    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            playerNearby = true;
        }
    }
}
