using UnityEngine;

public class BulletImpact : MonoBehaviour
{
    [Header("碰撞后释放的特效预制体")]
    public GameObject impactVFX;

    [Header("特效持续时间")]
    public float vfxLife = 2f;

    void OnCollisionEnter(Collision collision)
    {
        // 1. 释放 VFX
        if (impactVFX != null)
        {
            GameObject vfx = Instantiate(impactVFX, transform.position, Quaternion.identity);
            Destroy(vfx, vfxLife);
        }

        // 2. 销毁子弹本体
        Destroy(gameObject);
    }
}
