// Main CLI entry point for yuecharts
// Similar to echarts/src/echarts.ts but simplified for static SVG rendering

///|
/// CLI entry point: reads JSON from stdin and renders the chart to SVG on stdout.
/// Run with `Get-Content examples/bar.json | moon run cmd/main --target native`
fn main {
  let json_str = read_stdin()
  println(@lib.render(json_str))
}

///|
/// Read all bytes from stdin until EOF, returning the result as a String.
fn read_stdin() -> String {
  let buf = StringBuilder::new()
  while true {
    let ch = getchar()
    if ch == -1 {
      break
    }
    buf.write_char(ch.unsafe_to_char())
  }
  buf.to_string()
}

///|
extern "c" fn getchar() -> Int = "getchar"
