using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CheckIsGround : MonoBehaviour
{
    RaycastHit hit;

    public bool Check()
    {
        if (Physics.Raycast(transform.position, Vector3.down, out hit, 0.3f))
        {
            return true;
        }
        return false;

    }
}