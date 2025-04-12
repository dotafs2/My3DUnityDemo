using UnityEngine;

public class EnemySimpleAI : MonoBehaviour
{
    [Header("目标与移动")]
    public Transform player;
    public float detectRange = 10f;   // 侦测半径
    public float attackDistance = 1f;   // 停止移动并开始攻击的距离
    public float moveSpeed = 3f;   // 追击速度

    [Header("生命值 & 死亡")]
    public int maxHP = 10;          // 总血量（10 = 被打一下就死）
    public GameObject deathVFX;         // 指定死亡特效预制体
    public float vfxLife = 3f;          // 特效存活时间

    private int currentHP;
    private Animator animator;
    private bool isAttacking = false;
    private bool isDead = false;

    void Start()
    {
        animator = GetComponent<Animator>();
        currentHP = maxHP;
    }

    void Update()
    {
        if (isDead || player == null) return;

        float distance = Vector3.Distance(transform.position, player.position);

        // ────── 追击 ──────
        if (distance < detectRange && distance > attackDistance && !isAttacking)
        {
            animator.Play("FlyHeadElite_Escape_loop");

            // 朝向玩家（仅旋转 y 轴）
            Vector3 lookDir = player.position - transform.position;
            lookDir.y = 0;
            transform.rotation = Quaternion.Slerp(
                transform.rotation,
                Quaternion.LookRotation(lookDir),
                Time.deltaTime * 5f);

            // 向玩家移动，但保持 attackDistance
            Vector3 dir = (player.position - transform.position).normalized;
            transform.position += dir * moveSpeed * Time.deltaTime;
        }
        // ────── 攻击 ──────
        else if (distance <= attackDistance && !isAttacking)
        {
            isAttacking = true;
            animator.Play("FlyHeadElite_Attack");   // 把动画名字换成真正的攻击动画
        }
    }

    // ───────────────────────── 受击逻辑 ─────────────────────────
    // 触发器或碰撞器命中时调用；要求武器物体的 Tag 设为 "Weapon"
    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Weapon"))
        {
            TakeDamage(10);
        }
    }

    // 如果你用的是非 Trigger 的 Collider，可把上面改成 OnCollisionEnter
    // private void OnCollisionEnter(Collision collision) { ... }

    void TakeDamage(int dmg)
    {
        if (isDead) return;

        currentHP -= dmg;
        if (currentHP <= 0)
        {
            Die();
        }
        else
        {
            // 可以在这里播放受击动画或粒子
            Debug.Log($"小怪受伤，剩余血量: {currentHP}");
        }
    }

    void Die()
    {
        if (isDead) return;
        isDead = true;

        // 1. 生成死亡特效（放在场景根节点，避免随敌人一起被删）
        if (deathVFX != null)
        {
            GameObject fx = Instantiate(deathVFX, transform.position, Quaternion.identity);
            Destroy(fx, vfxLife);   // vfxLife 秒后自动清理
        }

        // 2. 立刻销毁敌人
        Destroy(gameObject);        // 不再等待动画或 5 秒延迟
    }

}
