using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Capture : MonoBehaviour
{
    private int count = 1;

    private void Update()
    {
        if(Input.GetKeyDown(KeyCode.P))
        {
            ScreenCapture.CaptureScreenshot("WorldImage"+count+".png");
            Debug.Log("Captured "+ "WorldImage"+count);
            count++;
        }

    }

}
