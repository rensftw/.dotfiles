/**
 * /babysit <pr> — watch a GitHub PR's CI and have the agent fix failures until every check is green.
 *
 * The watching happens in code, so waiting costs no tokens and leaves the session usable. Once every check on
 * the PR head has finished and some failed, babysit hands the failures to the agent as a new turn. The agent
 * fixes, commits, and pushes. Then babysit watches the new head commit. It stops when all checks pass, the PR
 * closes, MAX_ROUNDS fix rounds run out, the head commit gets no checks within NO_CHECKS_TIMEOUT_MS, or you run
 * `/babysit stop`.
 *
 * Usage: `/babysit [pr]`, `/babysit status`, `/babysit stop`. <pr> is a URL, `52492`, or `#52492` (numbers resolve
 * against the current repository). Without it, babysit uses the open PR for the current branch, asking you to pick
 * when there are several.
 * Requires an authenticated `gh`, and Pi must run in a checkout of the PR branch.
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const POLL_MS = 30_000;
const MAX_ROUNDS = 10;
/** How long a head commit may have zero checks (no CI, `[skip ci]`, path filters) before babysit gives up. */
const NO_CHECKS_TIMEOUT_MS = 5 * 60_000;

interface Check {
  name: string;
  bucket: "pass" | "fail" | "pending" | "skipping" | "cancel";
  link: string;
  workflow: string;
  completedAt: string;
}

interface BranchPr {
  number: number;
  title: string;
  url: string;
  baseRefName: string;
  state: string;
  isCrossRepository: boolean;
}

interface Watch {
  url: string;
  number: number;
  rounds: number;
  /** Fingerprint of the failures last handed to the agent, so the same failures are never reported twice. */
  reported?: string;
  /** Head SHA seen all-green on the previous poll; green must hold for two polls to count. */
  greenSha?: string;
  /** When babysit first saw this head SHA with zero checks; cleared as soon as any check appears. */
  noChecksSince?: { sha: string; at: number };
  /** Latest progress line, shown in the footer and by /babysit status. */
  state: string;
  timer?: ReturnType<typeof setTimeout>;
}

function fixPrompt(watch: Watch, sha: string, failed: Check[]): string {
  const list = failed
    .map((c) => `- ${c.workflow ? `${c.workflow} / ` : ""}${c.name}${c.bucket === "cancel" ? " (cancelled)" : ""}: ${c.link}`)
    .join("\n");

  return `CI failed on ${watch.url} at ${sha.slice(0, 7)} (babysit round ${watch.rounds}/${MAX_ROUNDS}):
${list}

Fix it:
1. Make sure the local branch is at ${sha.slice(0, 7)}. If it is behind, \`git pull --ff-only\`. If it has unpushed commits or has diverged, stop and tell the user; don't reset, rebase, or push them.
2. Read the failing logs. For GitHub Actions links (…/runs/<run-id>/job/<job-id>): \`gh run view <run-id> --job <job-id> --log-failed\`. For other CI, follow the link.
3. Find the root cause and make the smallest correct fix. Never skip, disable, or loosen tests or checks to turn CI green.
4. Run the failing command locally when you can.
5. Commit only your fix and \`git push\`. Don't force-push or rewrite history.
6. If the failure is unrelated to this PR (a flaky test or a CI infrastructure outage), rerun it instead: \`gh run rerun <run-id> --failed\`.
7. If you can't fix it safely, explain why and stop.

Don't wait for CI yourself. End your turn after pushing or rerunning; babysit watches the next run and reports back.`;
}

export default function babysit(pi: ExtensionAPI) {
  let watch: Watch | undefined;

  async function gh(ctx: ExtensionContext, args: string[]): Promise<string> {
    const result = await pi.exec("gh", args, { cwd: ctx.cwd, timeout: 60_000 });
    if (result.killed) throw new Error("gh timed out");
    if (result.code !== 0) {
      throw new Error(
        (result.stderr || result.stdout).trim() || `gh failed with exit code ${result.code} (is gh installed and authenticated?)`,
      );
    }
    return result.stdout;
  }

  /** Open PRs for the checked-out branch, in the repository gh resolves for the working directory. */
  async function branchPrs(ctx: ExtensionContext): Promise<{ branch: string; prs: BranchPr[] }> {
    const git = await pi.exec("git", ["branch", "--show-current"], { cwd: ctx.cwd });
    const branch = git.stdout.trim();
    if (git.code !== 0 || !branch) throw new Error(`${ctx.cwd} is not on a git branch.`);

    const fields = "number,title,url,baseRefName,state,isCrossRepository";
    // --head matches the branch name only, so drop other people's fork PRs that reuse it.
    const listed: BranchPr[] = JSON.parse(await gh(ctx, ["pr", "list", "--head", branch, "--state", "open", "--json", fields]));
    const prs = listed.filter((pr) => !pr.isCrossRepository);
    // gh's own pick also follows branch tracking, so it finds fork PRs checked out under another local name.
    const tracked = await gh(ctx, ["pr", "view", "--json", fields]).then(JSON.parse, () => undefined);
    if (tracked?.state === "OPEN" && !prs.some((pr) => pr.url === tracked.url)) prs.push(tracked);
    return { branch, prs };
  }

  function status(ctx: ExtensionContext, text: string): void {
    if (watch) watch.state = text;
    ctx.ui.setStatus("babysit", `👶 #${watch?.number} ${text}`);
  }

  function stop(ctx: ExtensionContext, message?: string, level: "info" | "warning" = "info"): void {
    clearTimeout(watch?.timer);
    watch = undefined;
    ctx.ui.setStatus("babysit", undefined);
    if (message) ctx.ui.notify(`babysit: ${message}`, level);
  }

  async function poll(ctx: ExtensionContext, w: Watch): Promise<void> {
    const pr = JSON.parse(await gh(ctx, ["pr", "view", w.url, "--json", "state,headRefOid"]));
    if (watch !== w) return; // Stopped while gh was running.
    if (pr.state !== "OPEN") return stop(ctx, `#${w.number} is ${pr.state.toLowerCase()}; stopped.`);

    let checks: Check[];
    try {
      checks = JSON.parse(await gh(ctx, ["pr", "checks", w.url, "--json", "name,bucket,link,workflow,completedAt"]));
    } catch (error) {
      if (!/no checks reported/i.test(String(error))) throw error;
      checks = []; // A fresh push has no checks until CI picks it up.
    }
    if (watch !== w) return; // Stopped while gh was running.

    const pending = checks.filter((c) => c.bucket === "pending");
    const failed = checks.filter((c) => c.bucket === "fail" || c.bucket === "cancel");

    // The timeout covers only a commit with *zero* checks. Any check, even a queued one, clears it, so slow CI
    // (e.g. a 75-minute run) is never cut short: pending checks are waited on for as long as they take.
    if (checks.length === 0) {
      w.greenSha = undefined;
      if (w.noChecksSince?.sha !== pr.headRefOid) w.noChecksSince = { sha: pr.headRefOid, at: Date.now() };
      if (Date.now() - w.noChecksSince!.at >= NO_CHECKS_TIMEOUT_MS) {
        const minutes = NO_CHECKS_TIMEOUT_MS / 60_000;
        return stop(ctx, `no checks reported on ${pr.headRefOid.slice(0, 7)} after ${minutes} min; stopped.`, "warning");
      }
      return status(ctx, "waiting for checks");
    }
    w.noChecksSince = undefined;

    if (pending.length > 0) {
      w.greenSha = undefined;
      return status(ctx, `${pending.length}/${checks.length} checks running`);
    }

    if (failed.length === 0) {
      // Confirm on a second poll: slow-to-register workflows on a fresh push could otherwise be missed.
      if (w.greenSha !== pr.headRefOid) {
        w.greenSha = pr.headRefOid;
        return status(ctx, "green, confirming…");
      }
      pi.sendMessage(
        { customType: "babysit", content: `✅ All ${checks.length} CI checks are green on ${w.url} at ${pr.headRefOid.slice(0, 7)}.`, display: true },
        { triggerTurn: false },
      );
      return stop(ctx, `all checks green on #${w.number} 🎉`);
    }

    w.greenSha = undefined;
    const fingerprint = failed.map((c) => `${c.name}|${c.link}|${c.completedAt}`).sort().join("\n");
    if (fingerprint === w.reported) return status(ctx, `${failed.length} failed, waiting for a push or rerun`);
    if (w.rounds >= MAX_ROUNDS) return stop(ctx, `#${w.number} still failing after ${MAX_ROUNDS} fix rounds; stopped.`, "warning");

    w.rounds += 1;
    w.reported = fingerprint;
    status(ctx, `fixing ${failed.length} failure(s)`);
    pi.sendMessage(
      { customType: "babysit", content: fixPrompt(w, pr.headRefOid, failed), display: true },
      { triggerTurn: true, deliverAs: "followUp" },
    );
  }

  async function tick(ctx: ExtensionContext): Promise<void> {
    const w = watch;
    if (!w) return;

    try {
      // Let the agent finish its fix before judging CI again.
      if (ctx.isIdle() && !ctx.hasPendingMessages()) await poll(ctx, w);
    } catch (error) {
      if (watch === w) status(ctx, `gh error, retrying: ${String(error).split("\n")[0].slice(0, 80)}`);
    }

    if (watch === w) w.timer = setTimeout(() => void tick(ctx), POLL_MS);
  }

  pi.registerCommand("babysit", {
    description: "Watch a PR's CI and fix failures until all checks are green: /babysit [url | 123 | #123] | status | stop",
    getArgumentCompletions: (prefix) => {
      const items = [
        { value: "status", label: "status", description: "Show what babysit is watching" },
        { value: "stop", label: "stop", description: "Stop watching" },
      ].filter((item) => item.value.startsWith(prefix.trim()));
      return items.length > 0 ? items : null;
    },
    handler: async (args, ctx) => {
      const arg = args.trim();

      if (arg === "stop") return watch ? stop(ctx, "stopped.") : ctx.ui.notify("babysit: not running.", "info");
      if (arg === "status") {
        return ctx.ui.notify(
          watch ? `babysit: ${watch.url}: ${watch.state} (round ${watch.rounds}/${MAX_ROUNDS})` : "babysit: not running.",
          "info",
        );
      }
      if (watch) {
        return ctx.ui.notify(`babysit: already watching ${watch.url}. Run /babysit stop first.`, "warning");
      }

      try {
        const { branch, prs } = await branchPrs(ctx);
        let target: BranchPr | undefined;

        if (arg) {
          // gh resolves a URL, `123`, or `#123` against the current repository.
          const pr: BranchPr = JSON.parse(await gh(ctx, ["pr", "view", arg, "--json", "number,title,url,baseRefName,state"]));
          if (pr.state !== "OPEN") return ctx.ui.notify(`babysit: ${pr.url} is ${pr.state.toLowerCase()}.`, "error");
          if (!prs.some((p) => p.url === pr.url)) {
            return ctx.ui.notify(`babysit: ${branch} is not the PR branch. Run: gh pr checkout ${pr.url}`, "error");
          }
          target = pr;
        } else if (prs.length === 0) {
          return ctx.ui.notify(`babysit: no open PR for ${branch}. Check out the PR branch first: gh pr checkout <pr>`, "error");
        } else if (prs.length === 1) {
          target = prs[0];
        } else {
          const labels = prs.map((pr) => `#${pr.number} ${pr.title} (→ ${pr.baseRefName})`);
          const choice = await ctx.ui.select(`Open PRs for ${branch}`, labels);
          if (!choice) return ctx.ui.notify("babysit: no PR picked.", "info");
          target = prs[labels.indexOf(choice)];
        }

        watch = { url: target.url, number: target.number, rounds: 0, state: "starting…" };
        ctx.ui.notify(`babysit: watching #${target.number} ${target.title}`, "info");
        status(ctx, "starting…");
        void tick(ctx);
      } catch (error) {
        ctx.ui.notify(`babysit: ${error instanceof Error ? error.message : String(error)}`, "error");
      }
    },
  });

  pi.on("session_shutdown", (_event, ctx) => {
    clearTimeout(watch?.timer);
    watch = undefined;
    if (!ctx.hasUI) return;
    ctx.ui.setStatus("babysit", undefined);
  });
}
