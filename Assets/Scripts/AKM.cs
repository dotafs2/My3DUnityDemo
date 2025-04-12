using System.Collections;
using System.Collections.Generic;
using System.Threading;
using UnityEngine;

public class AKM : MonoBehaviour
{
    public GameObject BulletPrefab;

    public Transform firePoint;

    public float power = 1;

    public AudioSource ass;
    public AudioClip shootClip;
 
    public void Fire()
    {
 
        //�����ӵ� 
        GameObject bullet = GameObject.Instantiate<GameObject>(BulletPrefab);
        bullet.transform.position = firePoint.position;
        bullet.transform.rotation = firePoint.rotation;

        //���ӵ��ٶ�
        bullet.GetComponent<Rigidbody>().linearVelocity = firePoint.forward * power;
 
    }


    bool hasPressedTrigger = false;
    float timer = 0.2f;


    // Update is called once per frame
    void Update()
    {
        if (hasPressedTrigger)
        {
            timer-=Time.deltaTime;
            if (timer <0)
            {
                timer = 0.2f;
                Fire();
            }
        }
    }

    public void ActiveTrigger()
    {
        hasPressedTrigger = true;

        timer = 0;

        //���ſ�ǹ��Ч
        ass.Play();
    }

    public void ReleaseTrigger()
    {
        hasPressedTrigger = false;

        ass.Stop();
    }


}
