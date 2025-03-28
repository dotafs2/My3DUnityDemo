using UnityEngine;
using TMPro;
using System.Collections.Generic;

public class DialogueManager : MonoBehaviour
{
    [Header("UI组件")]
    public TMP_Text speakerText;
    public TMP_Text dialogueText;
    public GameObject dialoguePanel;

    [Header("对话数据")]
    public DialogueData dialogueData;

    private Queue<DialogueData.DialogueLine> linesQueue;
    private bool dialogueActive = false;

    void Start()
    {
        linesQueue = new Queue<DialogueData.DialogueLine>();
        dialoguePanel.SetActive(false);
    }

    // 开始播放对话
    public void StartDialogue()
    {
        dialoguePanel.SetActive(true);
        linesQueue.Clear();

        foreach (var line in dialogueData.dialogueLines)
            linesQueue.Enqueue(line);

        dialogueActive = true;
        DisplayNextLine();
    }

    // 显示下一句
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

    // 对话结束
    void EndDialogue()
    {
        dialoguePanel.SetActive(false);
        dialogueActive = false;
    }

    // 每一帧检查是否按下空格
    void Update()
    {
        if (dialogueActive && Input.GetKeyDown(KeyCode.T))
        {
            DisplayNextLine();
        }
    }
}
