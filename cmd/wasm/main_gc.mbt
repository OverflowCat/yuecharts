// WASM entry point for yuecharts
// Exports render(String) -> String for browser usage

///|
pub fn render(json_str : String) -> String {
  @lib.render(json_str)
}

///|
fn main {
  ()
}
