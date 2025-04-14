using UnityEngine;
using UnityEngine.XR.Interaction.Toolkit;
using System.Collections;

public class SwordPhysicsActivator : MonoBehaviour
{
    private Rigidbody rb;

    void Awake()
    {
        rb = GetComponent<Rigidbody>();
    }

    public void EnablePhysics()
    {
        Debug.Log("Physics Enabled!");
        StartCoroutine(EnablePhysicsNextFrame());
    }

    private IEnumerator EnablePhysicsNextFrame()
    {
        yield return null; // 延迟一帧
        rb.isKinematic = false;
        rb.useGravity = true;
    }
}
