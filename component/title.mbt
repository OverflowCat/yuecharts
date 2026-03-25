// Corresponds to: echarts/src/component/title/install.ts
// Title and subtitle are positioned using TitleOption.left / TitleOption.top.
//
// ECharts default token colors:
//   Title text:    tokens.color.neutral80 = #3c3c41
//   Subtext:       tokens.color.neutral70 = #54555a
//
// ECharts title defaults (from echarts/src/component/title/install.ts):
//   left: 'center', top: tokens.size.m (= 15), padding: 5
//   textStyle.fontSize: 18, textStyle.fontWeight: 'bold'
//   subtextStyle.fontSize: 12
//
// Pixel position: ty = top + padding = 15 + 5 = 20
// Text is drawn with dominant-baseline="central" so the center of the glyph
// is at ty + fontSize/2.  We emit x/y directly instead of transform=translate.

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
  // ECharts default: left='center'.
  let (tx, anchor) = match title.left {
    "center" => (opt.width * 0.5, @graphic.TextAnchor::middle())
    "right" => (opt.width - 10.0, @graphic.TextAnchor::end())
    _ => (10.0, @graphic.TextAnchor::start()) // "left", "auto", or pixel value
  }
  // ty = tokens.size.m + padding = 15 + 5 = 20
  // With dominant-baseline="central" the glyph center sits at ty + fontSize/2.
  let ty_title = 20.0 + 18.0 / 2.0 // = 29.0 (center of 18px title)
  if title.text != "" {
    elems.push(
      @graphic.Element::text_title(
        tx,
        ty_title,
        title.text,
        anchor,
        "#3c3c41", // tokens.color.neutral80
      ),
    )
  }
  if title.subtext != "" {
    // Subtext: fontSize=12, sits below title.
    // top = ty_title + fontSize/2 + gap(3) + subFontSize/2
    //     = 29 + 9 + 3 + 6 = 47
    let ty_sub = ty_title + 9.0 + 3.0 + 6.0
    elems.push(
      @graphic.Element::text_colored(
        tx,
        ty_sub,
        title.subtext,
        anchor,
        @graphic.TextBaseline::central(),
        "#54555a", // tokens.color.neutral70
      ),
    )
  }
  elems
}
