import type { AgentDefinition } from "./types.ts";

export const builtinAgents: AgentDefinition[] = [
  {
    name: "plan",
    kind: "main",
    source: "builtin",
    description: "Read-only exploration and implementation planning agent.",
    enabled: true,
    promptMode: "append",
    tools: ["read", "grep", "find", "ls", "bash", "subagent", "get_subagent_result", "steer_subagent"],
    thinking: "xhigh",
    prompt: [
      "You are the plan main agent.",
      "Explore and reason carefully, but do not mutate files or system state.",
      "Use subagents only when their delegated policy allows it.",
      "Produce concise plans, risks, and verification steps.",
    ].join("\n"),
    permission: {
      default: "allow",
      tools: {
        default: "allow",
        read: "allow",
        grep: "allow",
        find: "allow",
        ls: "allow",
        bash: "ask",
        subagent: "ask",
        get_subagent_result: "allow",
        steer_subagent: "ask",
        edit: "deny",
        write: "deny",
      },
      bash: {
        readOnly: true,
        default: "allow",
        deny: ["rm *", "sudo *", "chmod *", "chown *", ">", ">>"],
      },
      files: {
        default: "ask",
        read: { default: "allow" },
        write: {
          default: "deny",
          deny: ["/nix/store/**/*"]
        },
        edit: {
          default: "deny",
          deny: ["/nix/store/**/*"]
        },
        deny: [".git/**", "secrets/**", "**/.env", "**/.env.*"],
        external_directory: {
          default: "ask",
          allow: ["/nix/store/**/*"]
        },
      },
      agents: {
        default: "ask",
        scout: "allow",
        "docs-digger": "allow",
        project: "ask",
        model_override: "ask",
        tool_override: "ask",
      },
    },
  },
  {
    name: "build",
    kind: "main",
    source: "builtin",
    description: "Implementation agent with approval gates for mutations and commands.",
    enabled: true,
    promptMode: "append",
    tools: ["read", "grep", "find", "ls", "bash", "edit", "write", "subagent", "get_subagent_result", "steer_subagent"],
    thinking: "xhigh",
    prompt: [
      "You are the build main agent.",
      "Make focused implementation changes and use permission prompts for risky actions.",
      "Keep scope tight and preserve unrelated user work.",
    ].join("\n"),
    permission: {
      default: "ask",
      tools: {
        default: "ask",
        read: "allow",
        grep: "allow",
        find: "allow",
        ls: "allow",
        edit: "allow",
        write: "allow",
        bash: "allow",
        subagent: "allow",
        get_subagent_result: "allow",
        steer_subagent: "allow",
      },
      bash: {
        default: "allow",
        deny: ["\\brm\\s+-rf\\b", "\\bsudo\\b", "\\bgit\\s+reset\\s+--hard\\b"],
      },
      files: {
        default: "ask",
        read: { default: "allow" },
        write: {
          default: "allow",
          deny: ["/nix/store/**/*"]
        },
        edit: {
          default: "allow",
          deny: ["/nix/store/**/*"]
        },
        deny: [".git/**", "secrets/**"],
        external_directory: {
          default: "ask",
          allow: ["/nix/store/**/*"]
        },
      },
      agents: {
        default: "ask",
        scout: "allow",
        "docs-digger": "allow",
        codemodder: "ask",
        project: "ask",
        model_override: "ask",
        tool_override: "ask",
      },
    },
  },
  {
    name: "ask",
    kind: "main",
    source: "builtin",
    description: "Conversational and research agent with minimal local mutation access.",
    enabled: true,
    promptMode: "append",
    tools: ["read", "grep", "find", "ls", "subagent", "get_subagent_result"],
    thinking: "medium",
    prompt: [
      "You are the ask main agent.",
      "Answer questions, research, and clarify requirements.",
      "Avoid mutating files or executing shell commands unless explicitly approved.",
    ].join("\n"),
    permission: {
      default: "ask",
      tools: {
        default: "ask",
        read: "allow",
        grep: "allow",
        find: "allow",
        ls: "allow",
        subagent: "ask",
        get_subagent_result: "allow",
        bash: "deny",
        edit: "deny",
        write: "deny",
      },
      files: {
        default: "ask",
        read: { default: "allow" },
        write: {
          default: "deny",
          deny: ["/nix/store/**/*"]
        },
        edit: {
          default: "deny",
          deny: ["/nix/store/**/*"]
        },
        deny: [".git/**", "secrets/**", "**/.env", "**/.env.*"],
        external_directory: {
          default: "ask",
          allow: ["/nix/store/**/*"]
        },
      },
      agents: {
        default: "ask",
        scout: "allow",
        "docs-digger": "allow",
        project: "ask",
      },
    },
  },
];
