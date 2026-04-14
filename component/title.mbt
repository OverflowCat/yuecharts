// Corresponds to: echarts/src/component/title/install.ts
// Title and subtitle are positioned using TitleOption.left / TitleOption.top.
//
// ECharts default token colors:
//   Title text:    tokens.color.neutral80 = #3c3c41
//   Subtext:       tokens.color.quaternary = #86878c
//
// ECharts title defaults (from echarts/src/component/title/install.ts):
//   left: 'center', top: tokens.size.m (= 15), padding 5
//   textStyle.fontSize: 18, textStyle.fontWeight: 'bold'
//   subtextStyle.fontSize: 12
//
// The MoonBit port keeps the static title subset and renders the common
// top/bottom placement cases used by the examples. Text is drawn with
// dominant-baseline="central" so the serialized SVG matches ECharts' title
// baseline choice.

///|
/// Render the title and optional subtext to scene graph elements.
/// Returns an empty array if there is no title option set.
pub fn render_title(opt : @option.ChartOption) -> Array[@graphic.Element] {
  let title = match opt.title {
    None => return []
    Some(t) => t
  }
  if title.text == "" && title.subtext == "" {
    return []
  }
  let elems : Array[@graphic.Element] = []
  let (tx, anchor) = match title.left {
    "center" => (opt.width * 0.5, @graphic.TextAnchor::Middle)
    "right" => (opt.width - 10.0, @graphic.TextAnchor::End)
    _ => (10.0, @graphic.TextAnchor::Start)
  }
  let title_y = title_y_for_top(title.top, opt.height)
  let subtext_y = subtext_y_for_top(title.top, opt.height, title_y)
  if title.text != "" {
    elems.push(
      @graphic.Element::text_custom(
        tx,
        title_y,
        title.text,
        anchor,
        @graphic.TextBaseline::Central,
        title.text_style.color,
        title.text_style.font_size,
        title_font_family(
          opt.text_style.font_family,
          title.text_style.font_family,
        ),
        title.text_style.font_weight,
      ),
    )
  }
  if title.subtext != "" {
    elems.push(
      @graphic.Element::text_custom(
        tx,
        subtext_y,
        title.subtext,
        anchor,
        @graphic.TextBaseline::Central,
        title.subtext_style.color,
        title.subtext_style.font_size,
        title_font_family(
          opt.text_style.font_family,
          title.subtext_style.font_family,
        ),
        title.subtext_style.font_weight,
      ),
    )
  }
  elems
}

///|
fn title_y_for_top(top : String, height : Double) -> Double {
  match top {
    "bottom" => height - 14.0
    "center" | "middle" => height * 0.5 - 9.0
    _ => 29.0
  }
}

///|
fn subtext_y_for_top(top : String, height : Double, title_y : Double) -> Double {
  match top {
    "bottom" => height + 17.0
    "center" | "middle" => height * 0.5 + 13.0
    _ => title_y + 18.0
  }
}

///|
fn title_font_family(global : String?, fallback : String) -> String {
  match global {
    Some(font) if fallback == "sans-serif" => font
    _ => fallback
  }
}
