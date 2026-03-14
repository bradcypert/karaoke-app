/// JavaScript FFI bindings for browser APIs

@external(javascript, "../ffi.js", "getLocalStorage")
pub fn get_local_storage(key: String) -> String

@external(javascript, "../ffi.js", "setLocalStorage")
pub fn set_local_storage(key: String, value: String) -> Nil

@external(javascript, "../ffi.js", "removeLocalStorage")
pub fn remove_local_storage(key: String) -> Nil
