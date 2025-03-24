using UnityEngine;

public class NPCMovement : MonoBehaviour
{
    public float speed = 2f;
    public Animator animator;
    public Transform player;
    public float interactionDistance = 3f;
    private bool hasInteracted = false;

    void Update()
    {
        if (!hasInteracted)
        {
            // 沿Z轴向前走
            transform.Translate(Vector3.forward * speed * Time.deltaTime);
        }

        // 与玩家的距离检测
        float distance = Vector3.Distance(transform.position, player.position);
        if (distance < interactionDistance && Input.GetKeyDown(KeyCode.E))
        {
            Interact();
        }
    }

    void Interact()
    {
        hasInteracted = true;
        animator.SetTrigger("Interact");  // Animator中需设置同名Trigger
    }
}
