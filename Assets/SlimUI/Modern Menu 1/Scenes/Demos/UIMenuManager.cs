using UnityEngine;
using UnityEngine.SceneManagement;

public class UIMenuManager : MonoBehaviour
{
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha8))
        {
            LoadCampaignScene();
        }
    }

    public void LoadCampaignScene()
    {
        SceneManager.LoadScene("CloudSample"); 
    }
}
