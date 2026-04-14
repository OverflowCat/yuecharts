// Corresponds to: echarts/src/component/title/install.ts
// Title and subtitle are positioned using TitleOption.left / TitleOption.top.
//
// ECharts default token colors:
//   Title text:    tokens.color.neutral80 = #3c3c41
//   Subtext:       tokens.color.quaternary = #86878c
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
  let (tx, anchor) = match title.left {
    "center" => (opt.width * 0.5, @graphic.TextAnchor::Middle)
    "right" => (opt.width - 10.0, @graphic.TextAnchor::End)
    _ => (10.0, @graphic.TextAnchor::Start)
  }
  let ty_title = 20.0 + 18.0 / 2.0
  if title.text != "" {
    elems.push(
      @graphic.Element::text_custom(
        tx,
        ty_title,
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
    let ty_sub = ty_title + 9.0 + 3.0 + 6.0
    elems.push(
      @graphic.Element::text_custom(
        tx,
        ty_sub,
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
fn title_font_family(global : String?, fallback : String) -> String {
  match global {
    Some(font) if fallback == "sans-serif" => font
    _ => fallback
  }
}
