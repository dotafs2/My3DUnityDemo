using System.Collections;
using System.Collections.Generic;
using UnityEngine;
public class Gun : MonoBehaviour
{
    public GameObject BulletPrefab;
    public Transform firePoint;
    public float power = 1;
    public AudioSource ass;
    public AudioClip shootClip;
    public Transform Bag;

    public void Fire()
    {
        // �����ӵ�
        GameObject bullet = GameObject.Instantiate<GameObject>(BulletPrefab);
        bullet.transform.position = firePoint.position;
        bullet.transform.rotation = firePoint.rotation;
        // �ӵ��ٶ�
        bullet.GetComponent<Rigidbody>().linearVelocity = firePoint.forward * power;
        // ������Ч
        ass.PlayOneShot(shootClip);
    }

    public void BackToBag()
    {
        transform.position = Bag.position;
    }
}