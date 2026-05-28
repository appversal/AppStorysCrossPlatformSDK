let _data: Record<string, string> = {};

export function setPersonalizationData(data: Record<string, string>) {
  _data = data;
}

export function personalizeText(text: string): string {
  if (!text || text.trim() === '') return text;

  const regex = /\{\{([^|}\s]+)\s*\|\s*([^}]+)\}\}/g;
  return text.replace(regex, (_, variableName, fallbackValue) => {
    const key = variableName.trim();
    const fallback = fallbackValue.trim();
    return _data[key] ?? fallback;
  });
}

function replacePlaceholdersWithFallback(text: string): string {
  const regex = /\{\{[^|}\s]+\s*\|\s*([^}]+)\}\}/g;
  return text.replace(regex, (_, fallbackValue) => fallbackValue.trim());
}

export { replacePlaceholdersWithFallback };
