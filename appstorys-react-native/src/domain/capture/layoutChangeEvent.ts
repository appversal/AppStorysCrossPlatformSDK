type Listener = () => void;
const registry: Record<string, Set<Listener>> = {};

export function layoutChangeEvent(id: string) {
  registry[`layout_changed_${id}`]?.forEach(fn => fn());
}

export function subscribeToLayoutChange(id: string, callback: Listener) {
  const key = `layout_changed_${id}`;
  if (!registry[key]) registry[key] = new Set();
  registry[key].add(callback);
  return () => { registry[key]?.delete(callback); };
}
