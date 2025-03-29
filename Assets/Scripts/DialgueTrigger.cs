using UnityEngine;

public class DialogueTrigger : MonoBehaviour
{
    private bool triggered = false;

    void Update()
    {
        if (!triggered && Input.GetKeyDown(KeyCode.R))
        {
            FindFirstObjectByType<DialogueManager>().StartDialogue();
            triggered = true;
        }
    }
}
