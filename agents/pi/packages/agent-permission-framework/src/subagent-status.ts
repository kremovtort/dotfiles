import type { SubagentRunRecord } from "./types.ts";

export function finalSubagentStatus(options: { aborted: boolean; error?: string; softLimitReached: boolean }): SubagentRunRecord["status"] {
  if (options.aborted) return "aborted";
  if (options.error) return "failed";
  if (options.softLimitReached) return "steered";
  return "completed";
}
