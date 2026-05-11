import type { AgentDefinition, AgentIdentity, AuditEntry, PermissionApprovalBroker, PermissionPolicy, SubagentRunRecord } from "./types.ts";
import { composePolicies } from "./policy.ts";
import { AgentRuntimeState } from "./runtime.ts";

export type RunRecordInternal = SubagentRunRecord & {
  session?: any;
  resolve?: (run: SubagentRunRecord) => void;
  definition: AgentDefinition;
  effectivePolicy: PermissionPolicy;
  modelOverride?: string;
  thinkingOverride?: string;
  maxTurnsOverride?: number;
  signal?: AbortSignal;
  ctx?: unknown;
  inheritContext?: boolean;
  inheritExtensions?: boolean;
  inheritSkills?: boolean;
  approvalBroker?: PermissionApprovalBroker;
  approvalTimeoutMs?: number;
};

export type SubagentExecutorHelpers = {
  update: (run: RunRecordInternal) => void;
  audit: (audit: AuditEntry) => void;
};

export type SubagentExecutor = (run: RunRecordInternal, helpers: SubagentExecutorHelpers) => Promise<void> | void;

function id(): string {
  return `agent-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}

function normalizeMaxTurns(n: number | undefined): number | undefined {
  if (n == null || n === 0) return undefined;
  return Math.max(1, n);
}

function isTerminalStatus(status: SubagentRunRecord["status"]): boolean {
  return status === "completed" || status === "failed" || status === "aborted" || status === "steered";
}

export class SubagentRegistry {
  private runs = new Map<string, RunRecordInternal>();
  private queue: RunRecordInternal[] = [];
  private active = 0;
  private concurrency: number;
  private onUpdate?: (run: SubagentRunRecord) => void;
  private onAudit?: (audit: AuditEntry) => void;
  private executor?: SubagentExecutor;

  constructor(concurrency = 4, onUpdate?: (run: SubagentRunRecord) => void, onAudit?: (audit: AuditEntry) => void, executor?: SubagentExecutor) {
    this.concurrency = Math.max(1, concurrency);
    this.onUpdate = onUpdate;
    this.onAudit = onAudit;
    this.executor = executor;
  }

  list(): SubagentRunRecord[] {
    return [...this.runs.values()].map((run) => this.publicRun(run));
  }

  get(runId: string): RunRecordInternal | undefined {
    return this.runs.get(runId);
  }

  stats(): { active: number; queued: number; total: number } {
    return { active: this.active, queued: this.queue.length, total: this.runs.size };
  }

  setExecutor(executor: SubagentExecutor): void {
    this.executor = executor;
    this.pump();
  }

  restore(runs: SubagentRunRecord[]): void {
    const latest = new Map<string, SubagentRunRecord>();
    for (const run of runs) latest.set(run.id, run);
    for (const run of latest.values()) {
      const existing = this.runs.get(run.id);
      if (existing?.session && existing.status === "running") continue;
      const restored: SubagentRunRecord = { ...run };
      if (restored.status === "queued" || restored.status === "running") {
        restored.status = "aborted";
        restored.error = `${restored.error ?? ""}\nSubagent run was restored without a live session; it cannot continue.`.trim();
        restored.completedAt = restored.completedAt ?? Date.now();
      }
      this.runs.set(run.id, { ...restored, definition: { name: restored.agentName, kind: "subagent", source: restored.identity.source, description: restored.agentName, prompt: "", enabled: true, promptMode: "replace" }, effectivePolicy: {} });
    }
  }

  start(options: {
    agent: AgentDefinition;
    task: string;
    description?: string;
    cwd: string;
    parentIdentity: AgentIdentity | undefined;
    runtime: AgentRuntimeState;
    ctx: unknown;
    parentPolicy?: PermissionPolicy;
    background: boolean;
    modelOverride?: string;
    thinkingOverride?: string;
    maxTurnsOverride?: number;
    signal?: AbortSignal;
    inheritContext?: boolean;
    inheritExtensions?: boolean;
    inheritSkills?: boolean;
    approvalBroker?: PermissionApprovalBroker;
    approvalTimeoutMs?: number;
  }): { run: SubagentRunRecord; completion: Promise<SubagentRunRecord> } {
    const runId = id();
    const effectivePolicy = composePolicies(options.parentPolicy, options.agent.permission);
    const identity = options.runtime.createChild(options.parentIdentity, options.agent, runId, effectivePolicy);
    const run: RunRecordInternal = {
      id: runId,
      agentName: options.agent.name,
      description: options.description,
      task: options.task,
      status: "queued",
      output: "",
      identity,
      cwd: options.cwd,
      steering: [],
      definition: options.agent,
      effectivePolicy,
      modelOverride: options.modelOverride,
      thinkingOverride: options.thinkingOverride,
      maxTurnsOverride: options.maxTurnsOverride,
      maxTurns: normalizeMaxTurns(options.maxTurnsOverride ?? options.agent.maxTurns),
      signal: options.signal,
      ctx: options.ctx,
      inheritContext: options.inheritContext ?? options.agent.inheritContext ?? false,
      inheritExtensions: options.inheritExtensions ?? options.agent.inheritExtensions ?? false,
      inheritSkills: options.inheritSkills ?? options.agent.inheritSkills ?? true,
      approvalBroker: options.approvalBroker,
      approvalTimeoutMs: options.approvalTimeoutMs,
    };
    const completion = new Promise<SubagentRunRecord>((resolve) => {
      run.resolve = resolve;
    });
    this.runs.set(runId, run);
    this.queue.push(run);
    this.notify(run);
    this.pump();
    return { run: this.publicRun(run), completion };
  }

  async steer(runId: string, message: string): Promise<SubagentRunRecord | undefined> {
    const run = this.runs.get(runId);
    if (!run) return undefined;
    run.steering.push(message);
    if (run.status === "running" && run.session?.steer) await run.session.steer(message);
    this.notify(run);
    return this.publicRun(run);
  }

  publicRun(run: RunRecordInternal): SubagentRunRecord {
    const {
      session: _session,
      resolve: _resolve,
      definition: _definition,
      effectivePolicy: _effectivePolicy,
      modelOverride: _modelOverride,
      thinkingOverride: _thinkingOverride,
      maxTurnsOverride: _maxTurnsOverride,
      signal: _signal,
      ctx: _ctx,
      inheritContext: _inheritContext,
      inheritExtensions: _inheritExtensions,
      inheritSkills: _inheritSkills,
      approvalBroker: _approvalBroker,
      approvalTimeoutMs: _approvalTimeoutMs,
      ...serializable
    } = run;
    const queuedIndex = run.status === "queued" ? this.queue.findIndex((queued) => queued.id === run.id) : -1;
    return { ...serializable, queuedPosition: queuedIndex >= 0 ? queuedIndex + 1 : undefined };
  }

  private notify(run: RunRecordInternal): void {
    this.onUpdate?.(this.publicRun(run));
  }

  private pump(): void {
    while (this.active < this.concurrency && this.queue.length > 0) {
      const run = this.queue.shift()!;
      if (run.status !== "queued") continue;
      this.active++;
      run.status = "running";
      run.startedAt = run.startedAt ?? Date.now();
      this.notify(run);
      const executeRun = this.executor;
      Promise.resolve()
        .then(() => {
          if (!executeRun) throw new Error("Subagent executor is not configured.");
          return executeRun(run, {
            update: (updated) => this.notify(updated),
            audit: (audit) => this.onAudit?.(audit),
          });
        })
        .catch((error) => {
          run.status = "failed";
          run.error = `${run.error ?? ""}\n${error instanceof Error ? error.message : String(error)}`.trim();
        })
        .finally(() => {
          this.active = Math.max(0, this.active - 1);
          if (!isTerminalStatus(run.status)) {
            run.status = run.error ? "failed" : "completed";
          }
          run.completedAt = run.completedAt ?? Date.now();
          this.notify(run);
          run.resolve?.(this.publicRun(run));
          this.pump();
        });
    }
  }
}
