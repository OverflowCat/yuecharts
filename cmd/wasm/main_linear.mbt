// WASM (linear memory) entry point for yuecharts
// Uses I/O-based approach: JS feeds input via imported getchar,
// MoonBit outputs via spectest.print_char (println)

///|
pub fn version() -> String {
  @lib.version()
}

///|
fn get_input_char() -> Int = "input" "getchar"

///|
pub fn do_render() -> Unit {
  let buf = StringBuilder::new()
  while true {
    let ch = get_input_char()
    if ch == -1 {
      break
    }
    buf.write_char(ch.unsafe_to_char())
  }
  println(@lib.render(buf.to_string()))
}
