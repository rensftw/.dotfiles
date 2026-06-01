import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function lastAssistantText(ctx: any): string | undefined {
  const branch = ctx.sessionManager.getBranch();

  for (let i = branch.length - 1; i >= 0; i--) {
    const msg = branch[i]?.type === "message" ? branch[i].message : undefined;
    if (msg?.role !== "assistant") continue;

    if (msg.stopReason && msg.stopReason !== "stop") {
      ctx.ui.notify(
        `Last assistant message is incomplete (${msg.stopReason})`,
        "error",
      );
      return;
    }

    const text = (msg.content ?? [])
      .filter(
        (part: any) => part?.type === "text" && typeof part.text === "string",
      )
      .map((part: any) => part.text)
      .join("\n")
      .trim();

    if (text) return text;
  }
}

function removeCodeBlocks(text: string): string {
  let inCode = false;
  return text
    .split("\n")
    .filter((line) => {
      if (/^\s*(```|~~~)/.test(line)) {
        inCode = !inCode;
        return false;
      }
      return !inCode;
    })
    .join("\n");
}

function cleanQuestion(text: string): string {
  return text
    .replace(/^\s*(?:>\s*)?(?:[-*+]\s+|\d+[.)]\s+|⟦\d+⟧\s*|#+\s+|Q:\s*)*/i, "")
    .replace(/\s+/g, " ")
    .trim();
}

function extractQuestions(text: string): string[] {
  const seen = new Set<string>();
  const questions: string[] = [];

  for (const raw of removeCodeBlocks(text).split("\n")) {
    const line = raw.trim();
    if (!line.includes("?")) continue;

    // One prompt per line. Keeps option-style questions together:
    // "loyalty? ambition? peace?" should not become three prompts.
    const end = line.lastIndexOf("?") + 1;
    const tail = line.slice(end).match(/^[\]})"'”’]+/)?.[0] ?? "";
    const question = cleanQuestion(line.slice(0, end) + tail);
    const key = question.toLowerCase();

    if (question.length > 3 && !seen.has(key)) {
      seen.add(key);
      questions.push(question);
    }
  }

  return questions;
}

export default function answerExtension(pi: ExtensionAPI) {
  pi.registerCommand("answer", {
    description: "Answer questions from the last assistant message",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;
      if (!process.env.VISUAL && !process.env.EDITOR)
        process.env.VISUAL = "nvim";

      await ctx.waitForIdle();

      const source = lastAssistantText(ctx);
      if (!source) {
        ctx.ui.notify("No assistant message found", "error");
        return;
      }

      const questions = extractQuestions(source);
      if (questions.length === 0) {
        ctx.ui.notify(
          "No questions found in the last assistant message",
          "warning",
        );
        return;
      }

      const answers: string[] = [];
      for (let i = 0; i < questions.length; i++) {
        const answer = await ctx.ui.editor(
          `Answer ${i + 1}/${questions.length}: ${questions[i]}`,
          "",
        );
        if (answer === undefined) {
          ctx.ui.notify("Answering cancelled", "info");
          return;
        }
        answers.push(answer.trim());
      }

      const compiled = questions
        .map(
          (question, i) =>
            `${i + 1}. ${question}\n${answers[i] || "(no answer)"}`,
        )
        .join("\n\n");

      pi.sendUserMessage(`Answers to your questions:\n\n${compiled}`);
    },
  });
}
