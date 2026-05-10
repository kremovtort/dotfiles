const FRAMEWORK_EXTENSION_MARKER = "agent-permission-framework";

function textValues(value: unknown): string[] {
  if (!value) return [];
  if (typeof value === "string") return [value];
  if (typeof value !== "object") return [];
  const record = value as Record<string, unknown>;
  return [
    record.path,
    record.resolvedPath,
    record.extensionPath,
    (record.sourceInfo as Record<string, unknown> | undefined)?.path,
  ].filter((part): part is string => typeof part === "string");
}

function referencesFramework(value: unknown): boolean {
  return textValues(value).some((part) => part.includes(FRAMEWORK_EXTENSION_MARKER));
}

export function withoutRecursiveFrameworkExtension<T extends { extensions: any[]; errors: Array<{ path: string; error: string }>; runtime: unknown }>(base: T): T {
  return {
    ...base,
    extensions: base.extensions.filter((extension) => {
      if (String(extension?.path ?? "").startsWith("<inline:")) return true;
      return !referencesFramework(extension);
    }),
    errors: base.errors.filter((error) => !referencesFramework(error) && !error.error.includes(FRAMEWORK_EXTENSION_MARKER)),
  };
}
