using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;



[Serializable]
public class VolumetricCloudsRenderPassSetting
{
    public RenderPassEvent renderPassEvent;
    public int cloudDownSample = 2;
    public Material cloudRenderingMaterial;
    public Material bilateralBlurMaterial;
    public Material taaBlendMaterial;
    public Material finalBlendMaterial;
    public int bilateralBlurIteration = 0;
    public int bilateralBlurDownSample = 1;
}

public partial class Library
{
    public static Matrix4x4 GetViewProjectionMatrix(Camera cam)
    {
        return GL.GetGPUProjectionMatrix(cam.projectionMatrix, false) * cam.worldToCameraMatrix;
    }

    public static Matrix4x4 GetInverseViewProjectionMatrix(Camera cam)
    {
        return cam.cameraToWorldMatrix * GL.GetGPUProjectionMatrix(cam.projectionMatrix, false).inverse;
    }
}
public class BilateralBlur
{
    private RenderTexture tempRT0;
    private RenderTexture tempRT1;

    public void Blur(Material material, CommandBuffer cmd, RenderTexture target, int downsample, int iteration)
    {
        CreateResources(target, downsample);

        RenderTexture currentRT = tempRT0;
        RenderTexture nextRT = tempRT1;

        cmd.Blit(target, currentRT);

        for (int i = 0; i < iteration; i++)
        {
            cmd.Blit(currentRT, nextRT, material);

            RenderTexture swithRT = currentRT;
            currentRT = nextRT;
            nextRT = swithRT;
        }

        cmd.Blit(currentRT, target);
    }

    public void CreateResources(RenderTexture target, int downsample)
    {
        RenderTextureDescriptor descriptor = target.descriptor;
        descriptor.width /= downsample;
        descriptor.height /= downsample;

        if (tempRT0 != null && tempRT0.width == descriptor.width && tempRT0.height == descriptor.height)
        {
            return;
        }

        ReleaseResources();

        tempRT0 = RenderTexture.GetTemporary(descriptor);
        tempRT0.filterMode = FilterMode.Point;
        tempRT0.wrapMode = TextureWrapMode.Clamp;
        tempRT1 = RenderTexture.GetTemporary(descriptor);
        tempRT1.filterMode = FilterMode.Point;
        tempRT1.wrapMode = TextureWrapMode.Clamp;
    }

    public void ReleaseResources()
    {
        if (tempRT0 != null)
        {
            tempRT0.Release();
        }

        if (tempRT1 != null)
        {
            tempRT1.Release();
        }
    }
}
public class VolumetricCloudsRenderPass : ScriptableRenderPass
{
    public static RenderTexture currentCameraTarget0;
    public static RenderTexture currentCameraTarget1;
    public static RenderTexture currentCloudColor;
    public static RenderTexture taaBlendCloudColor;
    public static RenderTexture volumeLightColor;
    public static RenderTexture previousCameraTarget0;
    public static RenderTexture previousCloudColor;
    public static BilateralBlur bilateralBlur;
    public static bool previousCloudRTInited;
    public static Matrix4x4 previousCameraVP;

    private VolumetricCloudsRenderPassSetting setting;

    public VolumetricCloudsRenderPass(VolumetricCloudsRenderPassSetting setting)
    {
        this.setting = setting;
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        renderPassEvent = setting.renderPassEvent;

        if (VolumetricCloudsManager.instance == null)
        {
            return;
        }

        CreateTextures(renderingData);

        CommandBuffer cmd = CommandBufferPool.Get("VolumetricClouds");

        RenderCloud(cmd, renderingData);
        TAABlend(cmd, renderingData);
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
                bilateralBlur.Blur(setting.bilateralBlurMaterial, cmd, currentCloudColor, setting.bilateralBlurDownSample, setting.bilateralBlurIteration);
            }
        }
    }

    private void TAABlend(CommandBuffer cmd, RenderingData renderingData)
    {
        if (setting.taaBlendMaterial != null && Application.isPlaying)
        {
            if (previousCloudRTInited == false)
            {
                cmd.Blit(currentCameraTarget0, previousCameraTarget0);
                cmd.Blit(currentCloudColor, previousCloudColor);
                previousCloudRTInited = true;
            }

            setting.taaBlendMaterial.SetInt("_HasCameraChanged", renderingData.cameraData.camera.transform.hasChanged ? 1 : 0);
            renderingData.cameraData.camera.transform.hasChanged = false;

            setting.taaBlendMaterial.SetTexture("_CurrentCameraTarget0", currentCameraTarget0);
            setting.taaBlendMaterial.SetTexture("_CurrentCameraTarget1", currentCameraTarget1);
            setting.taaBlendMaterial.SetTexture("_CurrentCloudColor", currentCloudColor);
            setting.taaBlendMaterial.SetTexture("_PreviousCameraTarget0", previousCameraTarget0);
            setting.taaBlendMaterial.SetTexture("_PreviousCloudColor", previousCloudColor);
            setting.taaBlendMaterial.SetMatrix("_PreviousCameraVP", previousCameraVP);

            cmd.Blit(null, taaBlendCloudColor, setting.taaBlendMaterial);
            cmd.Blit(currentCameraTarget0, previousCameraTarget0);
            cmd.Blit(taaBlendCloudColor, previousCloudColor);
        }
        else
        {
            cmd.Blit(currentCloudColor, taaBlendCloudColor);
        }
    }

    private void BlitCloudToScreen(CommandBuffer cmd, RenderingData renderingData)
    {
        if (setting.finalBlendMaterial == null)
        {
            return;
        }

        cmd.Blit(taaBlendCloudColor, renderingData.cameraData.renderer.cameraColorTargetHandle, setting.finalBlendMaterial);

        previousCameraVP = Library.GetViewProjectionMatrix(renderingData.cameraData.camera);
    }

    private void CreateTextures(RenderingData renderingData)
    {
        int width = renderingData.cameraData.camera.pixelWidth / setting.cloudDownSample;
        int height = renderingData.cameraData.camera.pixelHeight / setting.cloudDownSample;

        if (currentCloudColor != null && currentCloudColor.width == width && currentCloudColor.height == height)
        {
            return;
        }

        ReleaseTextures();

        bilateralBlur = new BilateralBlur();

        RenderTextureDescriptor descriptor = new RenderTextureDescriptor(width, height, RenderTextureFormat.ARGBFloat, 0);
        currentCameraTarget0 = RenderTexture.GetTemporary(descriptor);
        currentCameraTarget0.filterMode = FilterMode.Point;

        currentCameraTarget1 = RenderTexture.GetTemporary(descriptor);
        currentCameraTarget1.filterMode = FilterMode.Point;

        previousCameraTarget0 = RenderTexture.GetTemporary(descriptor);
        previousCameraTarget0.filterMode = FilterMode.Point;

        descriptor = new RenderTextureDescriptor(width, height, RenderTextureFormat.ARGB32, 0);
        currentCloudColor = RenderTexture.GetTemporary(descriptor);
        currentCloudColor.filterMode = FilterMode.Point;

        taaBlendCloudColor = RenderTexture.GetTemporary(descriptor);
        taaBlendCloudColor.filterMode = FilterMode.Point;

        volumeLightColor = RenderTexture.GetTemporary(descriptor);
        volumeLightColor.filterMode = FilterMode.Point;

        previousCloudColor = RenderTexture.GetTemporary(descriptor);
        previousCloudColor.filterMode = FilterMode.Point;
        previousCloudRTInited = false;

        previousCameraVP = Library.GetViewProjectionMatrix(renderingData.cameraData.camera);
    }

    private void ReleaseTextures()
    {
        if (bilateralBlur != null)
        {
            bilateralBlur.ReleaseResources();
            bilateralBlur = null;
        }

        if (currentCameraTarget0 != null)
        {
            RenderTexture.ReleaseTemporary(currentCameraTarget0);
            currentCameraTarget0 = null;
        }

        if (currentCameraTarget1 != null)
        {
            RenderTexture.ReleaseTemporary(currentCameraTarget1);
            currentCameraTarget1 = null;
        }

        if (previousCameraTarget0 != null)
        {
            RenderTexture.ReleaseTemporary(previousCameraTarget0);
            previousCameraTarget0 = null;
        }

        if (currentCloudColor != null)
        {
            RenderTexture.ReleaseTemporary(currentCloudColor);
            currentCloudColor = null;
        }

        if (taaBlendCloudColor != null)
        {
            RenderTexture.ReleaseTemporary(taaBlendCloudColor);
            taaBlendCloudColor = null;
        }

        if (volumeLightColor != null)
        {
            RenderTexture.ReleaseTemporary(volumeLightColor);
            volumeLightColor = null;
        }

        if (previousCloudColor != null)
        {
            RenderTexture.ReleaseTemporary(previousCloudColor);
            previousCloudColor = null;
        }
    }
}