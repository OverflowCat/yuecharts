// Corresponds to: echarts/src/component/visualMap/ContinuousView.ts
//                  echarts/src/component/visualMap/VisualMapModel.ts
//                  echarts/src/component/visualMap/ContinuousModel.ts
//
// Static (non-interactive) rendering of continuous visualMap color legend bars.
// ECharts defaults used:
//   itemWidth=20, itemHeight=140  (DEFAULT_BAR_BOUND=[20,140])
//   orient="vertical", left=0, bottom=0 (VisualMapModel.defaultOption)
//   textGap=10, padding=15 (tokens.size.m)
//   textStyle.color = tokens.color.secondary = #54555a (neutral70)

///|
fn vm_parse_pos(s : String) -> Double {
  if s == "" || s == "auto" {
    0.0
  } else {
    let r = try? @strconv.parse_double(s)
    r.unwrap_or(0.0)
  }
}

///|
fn vm_clamp01(v : Double) -> Double {
  if v < 0.0 {
    0.0
  } else if v > 1.0 {
    1.0
  } else {
    v
  }
}

///|
fn vm_color_at_ratio(colors : Array[String], ratio : Double) -> String {
  if colors.length() == 0 {
    return "#cccccc"
  }
  if colors.length() == 1 {
    return colors[0]
  }
  let total = colors.length() - 1
  let scaled = vm_clamp01(ratio) * total.to_double()
  let index = scaled.floor().to_int()
  let next_index = if index + 1 < colors.length() { index + 1 } else { index }
  let local_t = scaled - index.to_double()
  let start_color = @graphic.Color::from_string(colors[index]).unwrap_or(
    @graphic.black,
  )
  let end_color = @graphic.Color::from_string(colors[next_index]).unwrap_or(
    start_color,
  )
  @graphic.Color::lerp(start_color, end_color, local_t).to_svg()
}

///|
fn vm_render_gradient_bar(
  elems : Array[@graphic.Element],
  colors : Array[String],
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  is_horizontal : Bool,
) -> Unit {
  // Render gradient as 20 discrete slices for smooth appearance
  let steps = 20
  let mut j = 0
  while j < steps {
    let t0 = j.to_double() / steps.to_double()
    let t1 = (j + 1).to_double() / steps.to_double()
    let t_center = (t0 + t1) / 2.0
    // For horizontal: t=0 → left (min), t=1 → right (max)
    // For vertical: t=0 → top (max), t=1 → bottom (min);
    //   ECharts draws gradient top=max, bottom=min for vertical
    let ratio = if is_horizontal { t_center } else { 1.0 - t_center }
    let color_str = vm_color_at_ratio(colors, ratio)
    let (sx, sy, sw, sh) = if is_horizontal {
      (x + t0 * w, y, (t1 - t0) * w, h)
    } else {
      (x, y + t0 * h, w, (t1 - t0) * h)
    }
    elems.push(@graphic.Element::rect_colored(sx, sy, sw, sh, color_str))
    j += 1
  }
}

///|
fn vm_format_number(n : Double) -> String {
  // Display integers without decimal point
  if n - n.floor() < 1.0e-9 && n.floor() - n < 1.0e-9 {
    n.to_int().to_string()
  } else {
    n.to_string()
  }
}

///|
/// Render all visualMap components (continuous type, static rendering).
/// Corresponds to ContinuousView.ts _buildView() / _renderBar().
pub fn render_visual_map(opt : @option.ChartOption) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let width = opt.width
  let height = opt.height
  // ECharts defaults from VisualMapModel.ts
  let padding = 15.0 // tokens.size.m
  let text_gap = 10.0 // textGap default
  let label_color = "#54555a" // tokens.color.secondary / neutral70
  let font_size = 12.0
  let mut i = 0
  while i < opt.visual_map.length() {
    let vm = opt.visual_map[i]
    if !vm.show {
      i += 1
      continue
    }
    // Resolve item dimensions (DEFAULT_BAR_BOUND = [20, 140])
    let item_w = vm.item_width.unwrap_or(20.0) // thickness
    let item_h = vm.item_height.unwrap_or(140.0) // length
    let is_horizontal = vm.orient == "horizontal"
    // Bar display dimensions:
    //   horizontal → rotated: displayed width=item_h, displayed height=item_w
    //   vertical   → natural:  displayed width=item_w, displayed height=item_h
    let bar_w = if is_horizontal { item_h } else { item_w }
    let bar_h = if is_horizontal { item_w } else { item_h }
    // Effective colors: prefer controller.inRange.color, then inRange.color
    let colors = match vm.controller_in_range {
      Some(ci) if ci.color.length() > 0 => ci.color
      _ => vm.in_range.color
    }
    // Compute bar position from left/right/top/bottom + padding
    let bar_x = match (vm.left, vm.right) {
      (Some(l), _) => vm_parse_pos(l) + padding
      (None, Some(r)) => width - vm_parse_pos(r) - padding - bar_w
      (None, None) => padding
    }
    let bar_y = match (vm.top, vm.bottom) {
      (Some(t), _) => vm_parse_pos(t) + padding + text_gap + font_size
      (None, Some(b)) => height - vm_parse_pos(b) - padding - bar_h
      (None, None) => height - padding - bar_h
    }
    // Draw gradient bar
    vm_render_gradient_bar(
      elems, colors, bar_x, bar_y, bar_w, bar_h, is_horizontal,
    )
    // Draw thin border rect around bar
    elems.push(
      @graphic.Element::rect_outlined(
        bar_x, bar_y, bar_w, bar_h, "#b7b9be", 0.5,
      ),
    )
    // Draw min/max labels
    let min_str = vm_format_number(vm.min)
    let max_str = vm_format_number(vm.max)
    if is_horizontal {
      // Min at left of bar, max at right of bar
      // Labels above bar: center at bar_y - text_gap
      let label_y = bar_y - text_gap
      elems.push(
        @graphic.Element::text_colored(
          bar_x,
          label_y,
          min_str,
          @graphic.TextAnchor::Start,
          @graphic.TextBaseline::Central,
          label_color,
        ),
      )
      elems.push(
        @graphic.Element::text_colored(
          bar_x + bar_w,
          label_y,
          max_str,
          @graphic.TextAnchor::End,
          @graphic.TextBaseline::Central,
          label_color,
        ),
      )
    } else {
      // Vertical: max label above bar, min label below bar
      let max_label_y = bar_y - text_gap
      let min_label_y = bar_y + bar_h + text_gap + font_size / 2.0
      let center_x = bar_x + bar_w / 2.0
      elems.push(
        @graphic.Element::text_colored(
          center_x,
          max_label_y,
          max_str,
          @graphic.TextAnchor::Middle,
          @graphic.TextBaseline::Central,
          label_color,
        ),
      )
      elems.push(
        @graphic.Element::text_colored(
          center_x,
          min_label_y,
          min_str,
          @graphic.TextAnchor::Middle,
          @graphic.TextBaseline::Central,
          label_color,
        ),
      )
    }
    i += 1
  }
  elems
}
