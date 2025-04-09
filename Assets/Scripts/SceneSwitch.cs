using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneSwitcher : MonoBehaviour
{
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Alpha7))
        {
            SceneManager.LoadScene(0); // SampleScene
        }
        else if (Input.GetKeyDown(KeyCode.Alpha8))
        {
            SceneManager.LoadScene(1); // DemoScene
        }
        else if (Input.GetKeyDown(KeyCode.Alpha9))
        {
            SceneManager.LoadScene(2); // cloud
        }
        else if (Input.GetKeyDown(KeyCode.Alpha0))
        {
            SceneManager.LoadScene(3); // testScene
        }
    }
}
