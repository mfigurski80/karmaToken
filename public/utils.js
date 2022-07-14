export function removeNumberKeys(o) {
  return Object.fromEntries(Object.keys(o)
    .filter(k => isNaN(k))
    .map(k => [k, o[k]])
  );
}
