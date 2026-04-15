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
/// Read all bytes from stdin until EOF, decoding UTF-8 into a Unicode String.
fn read_stdin() -> String {
  let buf = StringBuilder::new()
  while true {
    let b1 = getchar()
    if b1 == -1 {
      break
    }
    if b1 < 0x80 {
      // single-byte ASCII
      buf.write_char(b1.unsafe_to_char())
    } else if b1 >= 0xF0 {
      // 4-byte UTF-8 sequence
      let b2 = getchar()
      let b3 = getchar()
      let b4 = getchar()
      if b2 == -1 || b3 == -1 || b4 == -1 {
        break
      }
      let cp = ((b1 & 0x07) << 18) |
        ((b2 & 0x3F) << 12) |
        ((b3 & 0x3F) << 6) |
        (b4 & 0x3F)
      buf.write_char(cp.unsafe_to_char())
    } else if b1 >= 0xE0 {
      // 3-byte UTF-8 sequence (includes CJK)
      let b2 = getchar()
      let b3 = getchar()
      if b2 == -1 || b3 == -1 {
        break
      }
      let cp = ((b1 & 0x0F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
      buf.write_char(cp.unsafe_to_char())
    } else if b1 >= 0xC0 {
      // 2-byte UTF-8 sequence
      let b2 = getchar()
      if b2 == -1 {
        break
      }
      let cp = ((b1 & 0x1F) << 6) | (b2 & 0x3F)
      buf.write_char(cp.unsafe_to_char())
    } else {
      // continuation byte without leader (malformed), pass through
      buf.write_char(b1.unsafe_to_char())
    }
  }
  buf.to_string()
}

///|
extern "c" fn getchar() -> Int = "getchar"
