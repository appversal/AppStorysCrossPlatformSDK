const TOKEN_REGEX = /\{\{\s*([\w.-]+)\s*\}\}/g;

export function parsePersonalizationJson(json: string | null | undefined): Record<string, string> {
  if (!json || json === '{}') return {};
  try {
    const parsed = JSON.parse(json) as Record<string, unknown>;
    const output: Record<string, string> = {};
    for (const [key, value] of Object.entries(parsed)) {
      if (value == null) continue;
      output[key] = String(value);
    }
    return output;
  } catch {
    return {};
  }
}

export function personalizeText(template: string, values: Record<string, string>): string {
  return template.replace(TOKEN_REGEX, (_, token) => values[token] ?? '');
}

export function personalizeObject<T>(value: T, values: Record<string, string>): T {
  if (typeof value === 'string') {
    return personalizeText(value, values) as T;
  }

  if (Array.isArray(value)) {
    return value.map((entry) => personalizeObject(entry, values)) as T;
  }

  if (value && typeof value === 'object') {
    const output: Record<string, unknown> = {};
    Object.entries(value as Record<string, unknown>).forEach(([key, entry]) => {
      output[key] = personalizeObject(entry, values);
    });
    return output as T;
  }

  return value;
}

