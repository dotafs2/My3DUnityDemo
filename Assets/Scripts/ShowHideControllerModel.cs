using UnityEngine;
using UnityEngine.XR.Interaction.Toolkit;

public class ShowHideControllerModel : MonoBehaviour
{
    public void Grab()
    {
        ActionBasedController XC = transform.parent.GetComponent<ActionBasedController>();
        GameObject theModel = XC.model.gameObject;
        theModel.SetActive(false);
    }
    public void Release()
    {
        ActionBasedController XC = transform.parent.GetComponent<ActionBasedController>();
        GameObject theModel = XC.model.gameObject;
        theModel.SetActive(true);
    }
}