//Quest3极速开发  好玩的Unity菌
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VRSlider : MonoBehaviour
{

    [SerializeField] float progressValue = 0f;
 
    public float TheProgressValue
    {
        get { return progressValue; }
        set
        {
            if (progressValue != value)
            {
                progressValue = value;
                if (progressValue ==1f)
                {
                    onFinish?.Invoke();

                }
            }
        }
    }

    public Action onFinish;

 
    public Transform startPoint;
    public Transform endPoint;

    public Transform valueObj;
    public Transform valueObjShadow;

    Vector3 dirVector;

    void Start()
    {
 
        onFinish += TestOnFinish;
    }

    void Update()
    {

        dirVector = endPoint.position - startPoint.position;

        //实时获取shadow对象在当前Slider原点坐标系的z的投影
        float Zshadow = transform.InverseTransformPoint(valueObjShadow.position).z;

        Zshadow = Mathf.Clamp(Zshadow, 0f, endPoint.localPosition.z);
 

        float tempProgress = Zshadow / dirVector.magnitude;
 
        valueObj.position = startPoint.position + dirVector * progressValue;


        TheProgressValue = tempProgress;

    }

    public  void OnReleaseShdow()
    {
        valueObjShadow.transform.position = valueObj.position;
    }

    public void TestOnFinish()
    {
        Debug.Log("Slider Finish");
    }

}
