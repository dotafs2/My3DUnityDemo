using UnityEngine;
using System.Collections;   // ★ 协程用

public class NPCSimpleAI : MonoBehaviour
{
    /* ─────────────── 公开参数 ─────────────── */
    [Header("目标与范围")]
    public Transform player;
    public float detectRange = 12f;

    [Header("攻击节奏")]
    public float attackCooldown = 3f;

    [Header("投射物")]
    public GameObject projectilePrefab;
    public Transform firePoint;
    public float projectileSpeed = 10f;   // 子弹速度
    public float projectileLife = 5f;    // 自动销毁时间

    [Header("生命值 & 死亡")]
    public float maxHP = 100f;
    public GameObject deathVFX;
    public float fadeTime = 1.5f;

    [Header("碰撞伤害")]
    public string weaponTag = "Weapon";   // 碰撞武器的 Tag
    public float collisionDamage = 10f;   // 每次扣血
    public float damageCooldown = 10f;    // 冷却时间（秒）

    /* ─────────────── 私有变量 ─────────────── */
    float currentHP;
    bool isDead = false;

    Animator anim;
    bool hasPosed = false;
    float cooldownTimer = 0f;
    float lastDamageTime = -Mathf.Infinity;   // 上次受击时间

    /* ─────────────── Unity 生命周期 ─────────────── */
    void Start()
    {
        anim = GetComponent<Animator>();
        if (firePoint == null) firePoint = transform;
        currentHP = maxHP;
    }

    void Update()
    {
        if (isDead || player == null) return;

        float dist = Vector3.Distance(transform.position, player.position);

        // ① 首次进入范围 → Pose
        if (!hasPosed && dist <= detectRange)
        {
            anim.SetTrigger("Pose");
            hasPosed = true;
            return;
        }

        if (!hasPosed) return;

        FacePlayer();

        // ② Idle 状态下计时 → Attack
        if (IsInState("GoldenRoc_Idle_00_loop"))
        {
            cooldownTimer -= Time.deltaTime;
            if (cooldownTimer <= 0f && dist <= detectRange)
            {
                DoAttack();
                cooldownTimer = attackCooldown;
            }
        }
    }

    /* ─────────────── 攻击相关 ─────────────── */
    void DoAttack()
    {
        anim.SetTrigger("Attack");
        SpawnProjectile();          // 也可放到动画事件里调用
    }

    public void SpawnProjectile()
    {
        if (!projectilePrefab || !player) return;

        // 1) 实例化
        GameObject go = Instantiate(projectilePrefab,
                                    firePoint.position,
                                    Quaternion.identity);

        // 2) 计算方向并朝向玩家
        Vector3 dir = (player.position - firePoint.position).normalized;
        go.transform.forward = dir;

        // 3) 若有 Rigidbody 则赋速度
        Rigidbody rb = go.GetComponent<Rigidbody>();
        if (rb) rb.linearVelocity = dir * projectileSpeed;

        // 4) 一定时间后销毁
        Destroy(go, projectileLife);
    }

    /* ─────────────── 受击 / 死亡 ─────────────── */
    public void TakeDamage(float dmg)
    {
        if (isDead) return;
        Debug.Log($"{gameObject.name} 受到攻击，扣血 {dmg}，剩余 HP: {currentHP}");  // ★ 日志输出：受伤
        currentHP -= dmg;
        if (currentHP <= 0f) StartCoroutine(Die());
    }

    IEnumerator Die()
    {
        Debug.Log($"{gameObject.name} fs test : dead");
        isDead = true;
        if (anim) anim.SetTrigger("Dead");
        if (deathVFX) Instantiate(deathVFX, transform.position, Quaternion.identity);

        Collider col = GetComponent<Collider>();
        if (col) col.enabled = false;

        Vector3 startScale = transform.localScale;
        float t = 0f;
        while (t < fadeTime)
        {
            t += Time.deltaTime;
            float k = 1f - t / fadeTime;      // 1 → 0
            transform.localScale = startScale * k;
            yield return null;
        }
        Destroy(gameObject);
    }

    /* ─────────────── 碰撞检测 ─────────────── */
    void OnTriggerEnter(Collider other)   // 如果用碰撞器而非触发器，可改为 OnCollisionEnter
    {
        
        if (isDead) return;

        if (other.CompareTag(weaponTag) && Time.time - lastDamageTime >= damageCooldown)
        {
            lastDamageTime = Time.time;
            TakeDamage(collisionDamage);
        }
    }

    /* ─────────────── 工具函数 ─────────────── */
    void FacePlayer()
    {
        Vector3 look = player.position;
        look.y = transform.position.y;
        transform.LookAt(look);
    }

    bool IsInState(string stateName)
    {
        return anim.GetCurrentAnimatorStateInfo(0).IsName(stateName);
    }
}
