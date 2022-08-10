export const hi = "hi";

export * from "./contracts";
export * as addresses from "./addresses.json";

export function getAddressesFor(id) {
  return Object.values(addresses).find((address) => address.id === id);
}