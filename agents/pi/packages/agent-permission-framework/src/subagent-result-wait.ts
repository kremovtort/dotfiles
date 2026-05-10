import type { SubagentRunRecord } from "./types.ts";

export function shouldWaitForSubagentResult(wait: boolean | undefined, run: Pick<SubagentRunRecord, "status">): boolean {
  return wait === true && (run.status === "queued" || run.status === "running");
}

export async function waitForSubagentResult(
  run: Pick<SubagentRunRecord, "status">,
  options: { signal?: AbortSignal; intervalMs?: number; onProgress?: () => void } = {},
): Promise<"completed" | "cancelled"> {
  if (run.status !== "queued" && run.status !== "running") return "completed";
  options.onProgress?.();
  if (options.signal?.aborted) return "cancelled";

  return new Promise((resolve) => {
    let settled = false;
    let interval: ReturnType<typeof setInterval> | undefined;
    const intervalMs = options.intervalMs ?? 1000;

    const cleanup = () => {
      if (interval) clearInterval(interval);
      options.signal?.removeEventListener("abort", onAbort);
    };
    const finish = (outcome: "completed" | "cancelled") => {
      if (settled) return;
      settled = true;
      cleanup();
      resolve(outcome);
    };
    const isTerminal = () => run.status !== "queued" && run.status !== "running";
    const onAbort = () => finish(isTerminal() ? "completed" : "cancelled");
    const check = () => {
      if (isTerminal()) finish("completed");
      else options.onProgress?.();
    };

    options.signal?.addEventListener("abort", onAbort, { once: true });
    interval = setInterval(check, intervalMs);
    if (options.signal?.aborted) onAbort();
    else check();
  });
}
