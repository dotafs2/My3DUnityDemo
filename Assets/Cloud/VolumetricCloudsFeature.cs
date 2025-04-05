using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using static UnityEditor.MaterialProperty;

public class VolumetricCloudsRenderFeature : ScriptableRendererFeature
{
    public VolumetricCloudsRenderPassSetting setting;

    private VolumetricCloudsRenderPass pass;

    public override void Create()
    {
        if (pass == null)
            pass = new VolumetricCloudsRenderPass(setting);

        pass.renderPassEvent = setting.renderPassEvent; //  设置插入时机
    }


    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.camera.name != "MainCamera")
        {
          //  Debug.Log("dotafs");
            return;
        }

        if (pass == null)
            pass = new VolumetricCloudsRenderPass(setting);

        renderer.EnqueuePass(pass);
    }
}