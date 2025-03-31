using System;
using System.Collections;
using System.Collections.Generic;
using GLTFast.Schema;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using static Unity.VisualScripting.Member;

// ≈‰÷√Ω·ππ
[Serializable]
public class VolumetricCloudsRenderPassSetting
{
    public RenderPassEvent renderPassEvent;
    public int cloudDownSample = 2;
    public UnityEngine.Material cloudRenderingMaterial;
    public UnityEngine.Material bilateralBlurMaterial;
    public UnityEngine.Material taaBlendMaterial;
    public UnityEngine.Material finalBlendMaterial;
    public int bilateralBlurIteration = 0;
    public int bilateralBlurDownSample = 1;
}

public class VolumetricCloudsRenderPass : ScriptableRenderPass
{
    // The world-space position of each ray's key point during raymarching, and cloud density.
    public static RenderTexture currentCameraTarget0;
    // The vector of each ray's key point during raymarching, and light intensity.
    public static RenderTexture currentCameraTarget1;

    public static RenderTexture currentCloudColor;
    public static RenderTexture taaBlendCloudColor;
    public static RenderTexture volumeLightColor;
    public static RenderTexture previousCameraTarget0;
    public static RenderTexture previousCloudColor;
  //  public static BilateralBlur bilateralBlur;
    public static bool previousCloudRTInited;
    public static Matrix4x4 previousCameraVP;

    private VolumetricCloudsRenderPassSetting setting;

    public VolumetricCloudsRenderPass(VolumetricCloudsRenderPassSetting setting)
    {
        this.setting = setting;
    }



    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get("VolumetricClouds");

        RenderCloud(cmd, renderingData);
        BlitCloudToScreen(cmd, renderingData);

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    private void RenderCloud(CommandBuffer cmd, RenderingData renderingData)
    {
        List<MeshRenderer> cloudMeshRenderers = VolumetricCloudsManager.instance.cloudMeshRenderer;
        if (cloudMeshRenderers.Count == 0)
        {
            return;
        }

        RenderTargetIdentifier[] renderTargetIdentifiers = new RenderTargetIdentifier[2];
        renderTargetIdentifiers[0] = currentCameraTarget0;
        renderTargetIdentifiers[1] = currentCameraTarget1;

        cmd.SetRenderTarget(renderTargetIdentifiers, currentCameraTarget0);
        cmd.ClearRenderTarget(RTClearFlags.All, Color.clear, 0, 0);

        Light light = VolumetricCloudsManager.instance.directionalLight;
        if (light != null)
        {
            for (int i = 0; i < cloudMeshRenderers.Count; i++)
            {
                cloudMeshRenderers[i].sharedMaterial.SetVector("_LightDir", -light.transform.forward);
            }
        }

        for (int i = 0; i < cloudMeshRenderers.Count; i++)
        {
            cloudMeshRenderers[i].sharedMaterial.SetVector("_BoundMin", cloudMeshRenderers[i].bounds.min);
            cloudMeshRenderers[i].sharedMaterial.SetVector("_BoundMax", cloudMeshRenderers[i].bounds.max);
            cmd.DrawRenderer(cloudMeshRenderers[i], cloudMeshRenderers[i].sharedMaterial);
        }

        if (setting.cloudRenderingMaterial != null)
        {
            setting.cloudRenderingMaterial.SetVector("_LightDir", -light.transform.forward);
            setting.cloudRenderingMaterial.SetColor("_LightColor", light.color);
            setting.cloudRenderingMaterial.SetTexture("_CurrentCameraTarget0", currentCameraTarget0);
            setting.cloudRenderingMaterial.SetTexture("_CurrentCameraTarget1", currentCameraTarget1);
            cmd.Blit(null, currentCloudColor, setting.cloudRenderingMaterial);

            if (setting.bilateralBlurIteration > 0 && setting.bilateralBlurMaterial != null)
            {
         //       bilateralBlur.Blur(setting.bilateralBlurMaterial, cmd, currentCloudColor, setting.bilateralBlurDownSample, setting.bilateralBlurIteration);
            }
        }
    }


    private void BlitCloudToScreen(CommandBuffer cmd, RenderingData renderingData) {
        if (setting.finalBlendMaterial == null) {
            return;
        }

        cmd.Blit(currentCloudColor, renderingData.cameraData.renderer.cameraColorTargetHandle, setting.finalBlendMaterial);
    }

}
