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
  let title_items = if opt.titles.is_empty() {
    match opt.title {
      Some(t) => [t]
      None => []
    }
  } else {
    opt.titles
  }
  if title_items.is_empty() {
    return []
  }
  let elems : Array[@graphic.Element] = []
  for i, _ in title_items {
    let title = title_items[i]
    if title.text == "" && title.subtext == "" {
      continue
    }

    let tx = resolve_title_x(title, opt.width)
    let anchor = resolve_title_anchor(title)
    let top = resolve_title_top(title, opt.height)

    if title.text != "" {
      let ty_title = top + title.text_style.font_size / 2.0
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
      let ty_sub = if title.text != "" {
        top +
        title.text_style.font_size +
        8.0 +
        title.subtext_style.font_size / 2.0
      } else {
        top + title.subtext_style.font_size / 2.0
      }
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
  }
  elems
}

///|
fn parse_pct_or_px(s : String, reference : Double) -> Double {
  if s.has_suffix("%") {
    let inner = s[:s.length() - 1]
    let r = try? @string.parse_double(inner.to_string())
    match r {
      Ok(v) => v / 100.0 * reference
      Err(_) => 0.0
    }
  } else {
    let r = try? @string.parse_double(s)
    match r {
      Ok(v) => v
      Err(_) => 0.0
    }
  }
}

///|
fn resolve_title_x(title : @option.TitleOption, width : Double) -> Double {
  match title.left {
    "left" => 10.0
    "center" => width * 0.5
    "right" => width - 10.0
    v => parse_pct_or_px(v, width)
  }
}

///|
fn resolve_title_top(title : @option.TitleOption, height : Double) -> Double {
  match title.top {
    "auto" => 20.0
    "top" => 20.0
    "center" | "middle" => height * 0.5
    "bottom" => height - 20.0
    v => parse_pct_or_px(v, height)
  }
}

///|
fn resolve_title_anchor(title : @option.TitleOption) -> @graphic.TextAnchor {
  match title.text_align {
    Some("left") => @graphic.TextAnchor::Start
    Some("center") => @graphic.TextAnchor::Middle
    Some("right") => @graphic.TextAnchor::End
    _ =>
      match title.left {
        "center" => @graphic.TextAnchor::Middle
        "right" => @graphic.TextAnchor::End
        _ => @graphic.TextAnchor::Start
      }
  }
}

///|
fn title_font_family(global : String?, fallback : String) -> String {
  match global {
    Some(font) if fallback == "sans-serif" => font
    _ => fallback
  }
}
