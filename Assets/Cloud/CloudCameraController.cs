using UnityEngine;

public class FreeCameraController : MonoBehaviour
{
    [Header("移动设置")]
    [Tooltip("摄像机移动速度")]
    public float moveSpeed = 5.0f;
    [Tooltip("按住Shift键加速倍率")]
    public float sprintMultiplier = 2.0f;

    [Header("鼠标设置")]
    [Tooltip("鼠标灵敏度")]
    public float mouseSensitivity = 2.0f;
    [Tooltip("是否锁定鼠标光标")]
    public bool lockCursor = true;
    [Tooltip("最大俯仰角度")]
    public float maxPitchAngle = 90.0f;

    // 相机旋转
    private float yaw = 0.0f;
    private float pitch = 0.0f;

    // 移动方向
    private Vector3 moveDirection;

    private void Start()
    {
        // 初始化相机角度
        yaw = transform.eulerAngles.y;
        pitch = transform.eulerAngles.x;

        // 锁定鼠标光标
        if (lockCursor)
        {
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }
    }

    private void Update()
    {
        // 处理鼠标输入
        HandleMouseLook();

        // 处理键盘输入
        HandleMovement();

        // 按ESC键解锁鼠标
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }
    }

    private void HandleMouseLook()
    {
        // 获取鼠标输入
        float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity;
        float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity;

        // 计算新的相机方向
        yaw += mouseX;
        pitch -= mouseY; // 反转Y轴，使向上移动鼠标让相机向上看
        pitch = Mathf.Clamp(pitch, -maxPitchAngle, maxPitchAngle); // 限制俯仰角度

        // 应用旋转
        transform.rotation = Quaternion.Euler(pitch, yaw, 0.0f);
    }

    private void HandleMovement()
    {
        // 重置移动方向
        moveDirection = Vector3.zero;

        // 获取键盘输入
        if (Input.GetKey(KeyCode.W))
            moveDirection += transform.forward;
        if (Input.GetKey(KeyCode.S))
            moveDirection -= transform.forward;
        if (Input.GetKey(KeyCode.A))
            moveDirection -= transform.right;
        if (Input.GetKey(KeyCode.D))
            moveDirection += transform.right;
        if (Input.GetKey(KeyCode.E) || Input.GetKey(KeyCode.Space))
            moveDirection += transform.up;
        if (Input.GetKey(KeyCode.Q) || Input.GetKey(KeyCode.LeftControl))
            moveDirection -= transform.up;

        // 归一化方向向量，确保对角线移动不会更快
        if (moveDirection.magnitude > 0)
            moveDirection.Normalize();

        // 计算当前速度
        float currentSpeed = moveSpeed;
        if (Input.GetKey(KeyCode.LeftShift))
            currentSpeed *= sprintMultiplier;

        // 应用移动
        transform.position += moveDirection * currentSpeed * Time.deltaTime;
    }
}