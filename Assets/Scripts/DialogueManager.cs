using UnityEngine;
using TMPro;
using System.Collections.Generic;

public class DialogueManager : MonoBehaviour
{
    [Header("UI���")]
    public TMP_Text speakerText;
    public TMP_Text dialogueText;
    public GameObject dialoguePanel;

    [Header("�Ի�����")]
    public DialogueData dialogueData;

    private Queue<DialogueData.DialogueLine> linesQueue;
    private bool dialogueActive = false;

    void Start()
    {
        linesQueue = new Queue<DialogueData.DialogueLine>();
        dialoguePanel.SetActive(false);
    }

    // ��ʼ���ŶԻ�
    public void StartDialogue()
    {
        dialoguePanel.SetActive(true);
        linesQueue.Clear();

        foreach (var line in dialogueData.dialogueLines)
            linesQueue.Enqueue(line);

        dialogueActive = true;
        DisplayNextLine();
    }

    // ��ʾ��һ��
    public void DisplayNextLine()
    {
        if (linesQueue.Count == 0)
        {
            EndDialogue();
            return;
        }

        var line = linesQueue.Dequeue();
        speakerText.text = line.speaker;
        dialogueText.text = line.content;
    }

    // �Ի�����
    void EndDialogue()
    {
        dialoguePanel.SetActive(false);
        dialogueActive = false;
    }

    // ÿһ֡����Ƿ��¿ո�
    void Update()
    {
        if (dialogueActive && Input.GetKeyDown(KeyCode.T))
        {
            DisplayNextLine();
        }
    }
}
