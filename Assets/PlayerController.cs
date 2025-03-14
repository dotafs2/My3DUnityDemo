using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class DoubleJumpWithTrigger : MonoBehaviour
{
    [Header("�ƶ�����")]
    public float moveSpeed = 3f;    // ˮƽ�ƶ��ٶ�
    public float gravity = 9.81f;   // ����
    public float jumpForce = 5f;    // ��Ծ��ʼ�ٶ�

    [Header("��Ծ���")]
    public int maxJumpCount = 2;    // �����Ծ������ʵ�ֶ�������

    private CharacterController _charController;
    private Animator _animator;

    private float _verticalVelocity;  // ��ֱ�����ٶȣ�������Ӱ�죩
    private int _currentJumpCount;    // �Ѿ����˼���

    void Start()
    {
        _charController = GetComponent<CharacterController>();
        _animator = GetComponent<Animator>();

        // �տ�ʼ����Ծ��������
        _currentJumpCount = 0;
    }

    void Update()
    {
        // 1. ��ȡ������� (W/S �� ��/�¼�ͷ) - ǰ���ƶ�
        float verticalInput = Input.GetAxis("Vertical");

        // 2. ����ˮƽ�����ƶ���ֻ����Z��ǰ��
        Vector3 move = transform.forward * verticalInput * moveSpeed;

        // 3. ����Ƿ��ڵ���
        //    ֻҪ�������棬��������Ծ����
        if (_charController.isGrounded)
        {
            _currentJumpCount = 0;
            // ����ֱ�ٶȱ���һ��С��ֵ��ֱ���� 0
            _verticalVelocity = -0.1f;
        }

        // 4. ���¿ո񴥷���Ծ��֧�ֶ�������
        if (Input.GetKeyDown(KeyCode.Space))
        {
            // �����ǰ��Ծ���� < ����������
            if (_currentJumpCount < maxJumpCount)
            {
                _verticalVelocity = jumpForce;
                _currentJumpCount++;

                // ������Triggerֻ����һ�ι���
                _animator.SetTrigger("JumpTrigger");
            }
        }

        // 5. ��ɫ�ڿ��оͼ���������Ӱ��
        if (!_charController.isGrounded)
        {
            _verticalVelocity -= gravity * Time.deltaTime;
        }

        // 6. ����ֱ�ٶȺϲ����ƶ�����
        move.y = _verticalVelocity;

        // �� CharacterController �� Move() ���ƶ���ɫ
        _charController.Move(move * Time.deltaTime);

        // ============ ���� Animator ���� ============

        // �����Ҫ�� Animator �����֡��ڿ��С����ǡ��ڵ��桱��
        // ������Ӹ� InAir (bool) ������������ʾ��
        bool inAir = !_charController.isGrounded;
        _animator.SetBool("InAir", inAir);

        // Ҳ�ɰ�ǰ���ƶ������� Animator���������� Idle / Walk ����
        _animator.SetFloat("Vertical", verticalInput);
    }
}
