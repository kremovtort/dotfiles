type ParseResult = { frontmatter: Record<string, unknown>; body: string };

function countIndent(line: string): number {
  const match = line.match(/^ */);
  return match ? match[0].length : 0;
}

function stripInlineComment(value: string): string {
  let inSingle = false;
  let inDouble = false;
  for (let i = 0; i < value.length; i++) {
    const ch = value[i];
    const prev = value[i - 1];
    if (ch === "'" && !inDouble) inSingle = !inSingle;
    if (ch === '"' && !inSingle && prev !== "\\") inDouble = !inDouble;
    if (ch === "#" && !inSingle && !inDouble && (i === 0 || /\s/.test(value[i - 1]))) {
      return value.slice(0, i).trimEnd();
    }
  }
  return value.trimEnd();
}

function unquote(value: string): string {
  const trimmed = value.trim();
  if ((trimmed.startsWith('"') && trimmed.endsWith('"')) || (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
    const inner = trimmed.slice(1, -1);
    return trimmed.startsWith('"') ? inner.replace(/\\"/g, '"').replace(/\\\\/g, "\\") : inner;
  }
  return trimmed;
}

function parseScalar(raw: string): unknown {
  const value = stripInlineComment(raw).trim();
  if (value === "") return "";
  if (value === "true") return true;
  if (value === "false") return false;
  if (value === "null") return null;
  if (/^-?\d+$/.test(value)) return Number(value);
  if (value.startsWith("[") && value.endsWith("]")) {
    const inner = value.slice(1, -1).trim();
    if (!inner) return [];
    return inner.split(",").map((part) => unquote(part.trim()));
  }
  return unquote(value);
}

function parseYamlSubset(lines: string[], startIndex: number, indent: number): [unknown, number] {
  let index = startIndex;
  const isArray = lines[index] && countIndent(lines[index]) === indent && lines[index].trimStart().startsWith("- ");

  if (isArray) {
    const arr: unknown[] = [];
    while (index < lines.length) {
      const line = lines[index];
      if (!line.trim() || line.trimStart().startsWith("#")) {
        index++;
        continue;
      }
      const currentIndent = countIndent(line);
      if (currentIndent < indent) break;
      if (currentIndent !== indent || !line.trimStart().startsWith("- ")) break;
      const value = line.trimStart().slice(2);
      arr.push(parseScalar(value));
      index++;
    }
    return [arr, index];
  }

  const obj: Record<string, unknown> = {};
  while (index < lines.length) {
    const line = lines[index];
    if (!line.trim() || line.trimStart().startsWith("#")) {
      index++;
      continue;
    }
    const currentIndent = countIndent(line);
    if (currentIndent < indent) break;
    if (currentIndent > indent) break;

    const trimmed = line.trim();
    const match = trimmed.match(/^([^:]+):(.*)$/);
    if (!match) {
      index++;
      continue;
    }

    const key = match[1].trim();
    const rest = match[2] ?? "";
    if (rest.trim() !== "") {
      obj[key] = parseScalar(rest);
      index++;
      continue;
    }

    const nextIndex = index + 1;
    if (nextIndex >= lines.length) {
      obj[key] = {};
      index++;
      continue;
    }
    const [child, consumed] = parseYamlSubset(lines, nextIndex, indent + 2);
    obj[key] = child;
    index = consumed;
  }
  return [obj, index];
}

export function parseFrontmatter(content: string): ParseResult {
  const normalized = content.replace(/^\uFEFF/, "");
  if (!normalized.startsWith("---\n") && normalized.trim() !== "---") {
    return { frontmatter: {}, body: content };
  }

  const lines = normalized.split(/\r?\n/);
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") {
      end = i;
      break;
    }
  }
  if (end === -1) return { frontmatter: {}, body: content };

  const headerLines = lines.slice(1, end);
  const [frontmatter] = parseYamlSubset(headerLines, 0, 0);
  const body = lines.slice(end + 1).join("\n");
  return {
    frontmatter: typeof frontmatter === "object" && frontmatter !== null && !Array.isArray(frontmatter) ? frontmatter as Record<string, unknown> : {},
    body,
  };
}

export function toStringArray(value: unknown): string[] | undefined {
  if (Array.isArray(value)) return value.map(String).map((part) => part.trim()).filter(Boolean);
  if (typeof value === "string") return value.split(",").map((part) => part.trim()).filter(Boolean);
  return undefined;
}

export function toBoolean(value: unknown): boolean | undefined {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    if (value.toLowerCase() === "true") return true;
    if (value.toLowerCase() === "false") return false;
  }
  return undefined;
}
