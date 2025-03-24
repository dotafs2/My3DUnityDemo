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
            // ��Z����ǰ��
            transform.Translate(Vector3.forward * speed * Time.deltaTime);
        }

        // ����ҵľ�����
        float distance = Vector3.Distance(transform.position, player.position);
        if (distance < interactionDistance && Input.GetKeyDown(KeyCode.E))
        {
            Interact();
        }
    }

    void Interact()
    {
        hasInteracted = true;
        animator.SetTrigger("Interact");  // Animator��������ͬ��Trigger
    }
}
