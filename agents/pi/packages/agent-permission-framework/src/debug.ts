import { appendFileSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";

export function debugLog(event: string, data: unknown): void {
  const target = process.env.PI_AGENT_FRAMEWORK_DEBUG_LOG;
  if (!target) return;
  try {
    mkdirSync(dirname(target), { recursive: true });
    appendFileSync(target, JSON.stringify({ timestamp: Date.now(), event, data }) + "\n", "utf8");
  } catch {
    // Debug logging is best-effort and must never affect permission enforcement.
  }
}
