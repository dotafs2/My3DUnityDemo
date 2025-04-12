using UnityEngine;
using UnityEngine.InputSystem;
public class PlayerController : MonoBehaviour
{
    private CharacterController characterController;
    public float jumpSpeed = 10;
    public float gravity = 15;
    private Vector3 moveDirection;

    public InputActionReference input;

    public CheckIsGround cg;
    void Start()
    {
        characterController = GetComponent<CharacterController>();
    }

    void Update()
    {

        if (input.action.WasPressedThisFrame())
        {
            if (cg.Check())
            {
                moveDirection.y = jumpSpeed;
            }
            else
            {
                moveDirection = Vector3.zero;
            }
        }
        moveDirection.y -= gravity * Time.deltaTime;

        if (moveDirection.y < 0)
        {
            moveDirection.y = 0;
        }

        if (moveDirection.y > 0)
        {
            characterController.Move(moveDirection * Time.deltaTime);
        }

    }

}