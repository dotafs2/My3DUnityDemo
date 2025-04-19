using UnityEngine;

public class AttackInputHandler : MonoBehaviour
{
    private Animator animator;

    [Header("VFX Prefabs for Attacks")]
    public GameObject attack1VFX;
    public GameObject attack2VFX;
    public GameObject attack3VFX;
    public GameObject attack4VFX;
    public GameObject attack5VFX;

    [Header("VFX Settings")]
    public Transform vfxSpawnPoint;
    public float vfxLifetime = 2f;

    void Start()
    {
        animator = GetComponent<Animator>();
        if (vfxSpawnPoint == null)
            vfxSpawnPoint = transform;
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha1))
            TriggerAttack("Attack1", attack1VFX);
        else if (Input.GetKeyDown(KeyCode.Alpha2))
            TriggerAttack("Attack2", attack2VFX);
        else if (Input.GetKeyDown(KeyCode.Alpha3))
            TriggerAttack("Attack3", attack3VFX);
        else if (Input.GetKeyDown(KeyCode.Alpha4))
            TriggerAttack("Attack4", attack4VFX);
        else if (Input.GetKeyDown(KeyCode.Alpha5))
            TriggerAttack("Attack5", attack5VFX);
    }

    void TriggerAttack(string attackName, GameObject vfxPrefab)
    {
        if (animator != null)
            animator.SetTrigger(attackName);

        if (vfxPrefab != null)
        {
            GameObject vfx = Instantiate(vfxPrefab, vfxSpawnPoint.position, vfxSpawnPoint.rotation);
            Destroy(vfx, vfxLifetime);
        }
    }
}
