// Corresponds to: echarts/src/component/title/install.ts
// Title and subtitle are positioned using TitleOption.left / TitleOption.top.
//
// ECharts default token colors:
//   Title text:    tokens.color.neutral80 = #3c3c41
//   Subtext:       tokens.color.neutral70 = #54555a

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
  // Resolve horizontal position and text anchor.
  let (tx, anchor) = match title.left {
    "center" => (opt.width * 0.5, @graphic.TextAnchor::middle())
    "right" => (opt.width - 10.0, @graphic.TextAnchor::end())
    _ => (10.0, @graphic.TextAnchor::start()) // "left", "auto", or unrecognised
  }
  // Resolve vertical position (ECharts default top ≈ 14px)
  let ty = 14.0
  if title.text != "" {
    elems.push(
      @graphic.Element::text_colored(
        tx,
        ty,
        title.text,
        anchor,
        @graphic.TextBaseline::hanging(),
        "#3c3c41", // tokens.color.neutral80
      ),
    )
  }
  if title.subtext != "" {
    // Subtext sits one line below the title (font-size 12 + 4px gap)
    let sub_y = ty + 16.0
    elems.push(
      @graphic.Element::text_colored(
        tx,
        sub_y,
        title.subtext,
        anchor,
        @graphic.TextBaseline::hanging(),
        "#54555a", // tokens.color.neutral70
      ),
    )
  }
  elems
}
