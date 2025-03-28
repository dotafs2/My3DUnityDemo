using UnityEngine;
using System.Collections;

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
            transform.Translate(Vector3.forward * speed * Time.deltaTime);
        }

        float distance = Vector3.Distance(transform.position, player.position);
        if (distance < interactionDistance && Input.GetKeyDown(KeyCode.E))
        {
            Interact();
   
        }
    }

    void Interact()
    {
        hasInteracted = true;
        transform.rotation = Quaternion.Euler(0, transform.eulerAngles.x + 90f, 0);
        animator.SetTrigger("Interact");
        StartCoroutine(WaitAndDoSomething());
    }

    IEnumerator WaitAndDoSomething()
    {
        yield return new WaitForSeconds(0.7f); 
        GetComponent<Collider>().enabled = false; 
    }

}
