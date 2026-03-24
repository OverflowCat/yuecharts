///|
/// CLI entry point: reads a JSON file path from the first command-line argument
/// and renders the chart to SVG on stdout.
/// Run with `moon run cmd/main -- examples/bar.json` from the project root.
fn main {
  let args = @env.args()
  let json_str = if args.length() > 0 {
    read_file(args[0])
  } else {
    // Fallback: hardcoded demo bar chart for testing with no arguments.
    "{\"width\":600,\"height\":400,\"xAxis\":{\"type\":\"category\",\"data\":[\"Mon\",\"Tue\",\"Wed\",\"Thu\",\"Fri\",\"Sat\",\"Sun\"]},\"yAxis\":{\"type\":\"value\"},\"series\":[{\"type\":\"bar\",\"data\":[120,200,150,80,70,110,130]}]}"
  }
  println(@lib.render(json_str))
}

///|
/// Read a text file by path using the moonrun wasm filesystem host.
fn read_file(path : String) -> String {
  let extern_str = read_file_to_string_ffi(path)
  let buf = StringBuilder::new()
  let handle = begin_read_string(extern_str)
  while true {
    let ch = string_read_char(handle)
    if ch == -1 {
      break
    }
    buf.write_char(ch.unsafe_to_char())
  }
  finish_read_string(handle)
  buf.to_string()
}

///|
#external
priv type XExternString

///|
#external
priv type XStringReadHandle

///|
fn read_file_to_string_ffi(path : String) -> XExternString = "__moonbit_fs_unstable" "read_file_to_string"

///|
fn begin_read_string(s : XExternString) -> XStringReadHandle = "__moonbit_fs_unstable" "begin_read_string"

///|
fn string_read_char(handle : XStringReadHandle) -> Int = "__moonbit_fs_unstable" "string_read_char"

///|
fn finish_read_string(handle : XStringReadHandle) = "__moonbit_fs_unstable" "finish_read_string"
