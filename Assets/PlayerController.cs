using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class DoubleJumpWithTrigger : MonoBehaviour
{
    [Header("移动参数")]
    public float moveSpeed = 3f;    // 水平移动速度
    public float gravity = 9.81f;   // 重力
    public float jumpForce = 5f;    // 跳跃初始速度

    [Header("跳跃相关")]
    public int maxJumpCount = 2;    // 最大跳跃次数（实现二段跳）

    private CharacterController _charController;
    private Animator _animator;

    private float _verticalVelocity;  // 竖直方向速度（受重力影响）
    private int _currentJumpCount;    // 已经跳了几次

    void Start()
    {
        _charController = GetComponent<CharacterController>();
        _animator = GetComponent<Animator>();

        // 刚开始，跳跃次数清零
        _currentJumpCount = 0;
    }

    void Update()
    {
        // 1. 获取玩家输入 (W/S 或 上/下箭头) - 前后移动
        float verticalInput = Input.GetAxis("Vertical");

        // 2. 计算水平方向移动（只考虑Z轴前后）
        Vector3 move = transform.forward * verticalInput * moveSpeed;

        // 3. 检测是否在地面
        //    只要碰到地面，就重置跳跃次数
        if (_charController.isGrounded)
        {
            _currentJumpCount = 0;
            // 让竖直速度保持一个小负值或直接置 0
            _verticalVelocity = -0.1f;
        }

        // 4. 按下空格触发跳跃（支持二段跳）
        if (Input.GetKeyDown(KeyCode.Space))
        {
            // 如果当前跳跃次数 < 最大允许次数
            if (_currentJumpCount < maxJumpCount)
            {
                _verticalVelocity = jumpForce;
                _currentJumpCount++;

                // 这里用Trigger只触发一次过渡
                _animator.SetTrigger("JumpTrigger");
            }
        }

        // 5. 角色在空中就继续受重力影响
        if (!_charController.isGrounded)
        {
            _verticalVelocity -= gravity * Time.deltaTime;
        }

        // 6. 将竖直速度合并进移动向量
        move.y = _verticalVelocity;

        // 用 CharacterController 的 Move() 来移动角色
        _charController.Move(move * Time.deltaTime);

        // ============ 更新 Animator 参数 ============

        // 如果需要在 Animator 里区分“在空中”还是“在地面”，
        // 可以添加个 InAir (bool) 参数，这里演示：
        bool inAir = !_charController.isGrounded;
        _animator.SetBool("InAir", inAir);

        // 也可把前后移动量传给 Animator，用来区分 Idle / Walk 动画
        _animator.SetFloat("Vertical", verticalInput);
    }
}
