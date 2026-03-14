/**
 * localStorage helpers used by the Gleam FFI
 */

export function getLocalStorage(key) {
  try {
    return localStorage.getItem(key) ?? "";
  } catch {
    return "";
  }
}

export function setLocalStorage(key, value) {
  try {
    localStorage.setItem(key, value);
  } catch {
    // ignore (e.g. private browsing restrictions)
  }
}

export function removeLocalStorage(key) {
  try {
    localStorage.removeItem(key);
  } catch {
    // ignore
  }
}
