using UnityEngine;

public class AttackInputHandler : MonoBehaviour
{
    private Animator animator;

    void Start()
    {
        animator = GetComponent<Animator>();

    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha1))
            TriggerAttack("Attack1");
        else if (Input.GetKeyDown(KeyCode.Alpha2))
            TriggerAttack("Attack2");
        else if (Input.GetKeyDown(KeyCode.Alpha3))
            TriggerAttack("Attack3");
        else if (Input.GetKeyDown(KeyCode.Alpha4))
            TriggerAttack("Attack4");
        else if (Input.GetKeyDown(KeyCode.Alpha5))
            TriggerAttack("Attack5");
    }

    void TriggerAttack(string attackName)
    {
        if (animator != null)
        {
            animator.SetTrigger(attackName);
        }
    }
}
