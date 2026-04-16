// Corresponds to: echarts/src/component/visualMap/ContinuousView.ts
//                  echarts/src/component/visualMap/PiecewiseView.ts
//                  echarts/src/component/visualMap/VisualMapModel.ts
//                  echarts/src/component/visualMap/ContinuousModel.ts
//                  echarts/src/component/visualMap/PiecewiseModel.ts
//
// Static (non-interactive) rendering of visualMap components.
// The current implementation covers the continuous gradient bar path and the
// explicit piecewise legend path used by doc examples and regression fixtures.

///|
/// <=> echarts/src/component/visualMap/VisualMapModel.ts (layout value parsing)
fn vm_parse_pos(s : String, total : Double, fallback : Double) -> Double {
  if s == "" || s == "auto" {
    fallback
  } else if s.has_suffix("%") {
    let pct_str = s[:s.length() - 1]
    let parsed = try? @string.parse_double(pct_str.to_string())
    match parsed {
      Ok(pct) => total * pct / 100.0
      Err(_) => fallback
    }
  } else {
    let r = try? @string.parse_double(s)
    r.unwrap_or(fallback)
  }
}

///|
/// <=> echarts/src/component/visualMap/VisualMapView.ts:positionGroup
fn vm_resolve_start_x(
  left : String?,
  right : String?,
  total : Double,
  content : Double,
  padding : Double,
) -> Double {
  match left {
    Some(l) =>
      match l {
        "left" => padding
        "center" | "middle" => (total - content) * 0.5
        "right" => total - content - padding
        _ => vm_parse_pos(l, total, 0.0) + padding
      }
    None =>
      match right {
        Some(r) => total - vm_parse_pos(r, total, 0.0) - padding - content
        None => padding
      }
  }
}

///|
/// <=> echarts/src/component/visualMap/VisualMapView.ts:positionGroup
fn vm_resolve_start_y(
  top : String?,
  bottom : String?,
  total : Double,
  content : Double,
  padding : Double,
) -> Double {
  match top {
    Some(t) =>
      match t {
        "top" => padding
        "middle" | "center" => (total - content) * 0.5
        "bottom" => total - content - padding
        _ => vm_parse_pos(t, total, 0.0) + padding
      }
    None =>
      match bottom {
        Some(b) => total - vm_parse_pos(b, total, 0.0) - padding - content
        None => total - padding - content
      }
  }
}

///|
/// <=> echarts/src/component/visualMap/helper.ts:getItemAlign
fn vm_resolve_item_align(
  vm : @option.VisualMapOption,
  width : Double,
  start_x : Double,
  total_w : Double,
) -> String {
  match vm.align {
    "left" => "left"
    "right" => "right"
    _ =>
      if vm.orient == "horizontal" {
        "left"
      } else if start_x + total_w * 0.5 < width * 0.5 {
        "left"
      } else {
        "right"
      }
  }
}

///|
/// <=> echarts/src/component/visualMap/ContinuousView.ts:_renderEndsText
fn vm_continuous_end_text(
  vm : @option.VisualMapOption,
  end_index : Int,
) -> String {
  if vm.text.length() == 0 {
    ""
  } else {
    let idx = 1 - end_index
    if idx >= 0 && idx < vm.text.length() {
      vm.text[idx]
    } else {
      ""
    }
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
  let steps = 20
  let mut j = 0
  while j < steps {
    let t0 = j.to_double() / steps.to_double()
    let t1 = (j + 1).to_double() / steps.to_double()
    let t_center = (t0 + t1) / 2.0
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
fn vm_primary_colors(vm : @option.VisualMapOption) -> Array[String] {
  match vm.controller_in_range {
    Some(ci) if ci.color.length() > 0 => ci.color
    _ => if vm.color.length() > 0 { vm.color } else { vm.in_range.color }
  }
}

///|
fn vm_label_color(vm : @option.VisualMapOption, fallback : String) -> String {
  match vm.text_style {
    Some(style) => style.color.unwrap_or(fallback)
    None => fallback
  }
}

///|
fn vm_font_size(vm : @option.VisualMapOption, fallback : Double) -> Double {
  match vm.text_style {
    Some(style) => style.font_size.unwrap_or(fallback)
    None => fallback
  }
}

///|
fn vm_font_family(vm : @option.VisualMapOption, fallback : String) -> String {
  match vm.text_style {
    Some(style) => style.font_family.unwrap_or(fallback)
    None => fallback
  }
}

///|
fn vm_font_weight(vm : @option.VisualMapOption, fallback : String) -> String {
  match vm.text_style {
    Some(style) => style.font_weight.unwrap_or(fallback)
    None => fallback
  }
}

///|
fn vm_format_number(n : Double) -> String {
  if n - n.floor() < 1.0e-9 && n.floor() - n < 1.0e-9 {
    n.to_int().to_string()
  } else {
    n.to_string()
  }
}

///|
fn vm_reverse_strings(items : Array[String]) -> Array[String] {
  let result : Array[String] = []
  let mut i = items.length()
  while i > 0 {
    i -= 1
    result.push(items[i])
  }
  result
}

///|
priv struct VmPiecewiseViewItem {
  text : String
  color : String
  symbol : String
  selected : Bool
  show_symbol : Bool
  show_text : Bool
  width : Double
  height : Double
}

///|
fn vm_reverse_items(
  items : Array[VmPiecewiseViewItem],
) -> Array[VmPiecewiseViewItem] {
  let result : Array[VmPiecewiseViewItem] = []
  let mut i = items.length()
  while i > 0 {
    i -= 1
    result.push(items[i])
  }
  result
}

///|
fn vm_selected_state(vm : @option.VisualMapOption, key : String) -> Bool {
  for sel in vm.selected {
    if sel.key == key {
      return sel.selected
    }
  }
  true
}

///|
fn vm_inactive_color(vm : @option.VisualMapOption) -> String {
  match vm.out_of_range {
    Some(out_range) if out_range.color.length() > 0 => out_range.color[0]
    _ => "#d7dbe3"
  }
}

///|
fn vm_item_width(
  text : String,
  show_symbol : Bool,
  item_w : Double,
  text_gap : Double,
  char_w : Double,
) -> Double {
  let text_w = text.length().to_double() * char_w
  if show_symbol {
    if text == "" {
      item_w
    } else {
      item_w + text_gap + text_w
    }
  } else if text_w > item_w {
    text_w
  } else {
    item_w
  }
}

///|
fn vm_make_piecewise_item(
  text : String,
  color : String,
  symbol : String,
  selected : Bool,
  show_symbol : Bool,
  show_text : Bool,
  item_w : Double,
  item_h : Double,
  text_gap : Double,
  char_w : Double,
) -> VmPiecewiseViewItem {
  {
    text,
    color,
    symbol,
    selected,
    show_symbol,
    show_text,
    width: vm_item_width(text, show_symbol, item_w, text_gap, char_w),
    height: item_h,
  }
}

///|
fn vm_piece_text(piece : @option.VisualMapPieceOption) -> String {
  match piece.label {
    Some(label) if label != "" => label
    _ =>
      match piece.value {
        Some(value) => value
        None =>
          match (piece.min, piece.max) {
            (Some(min), Some(max)) =>
              "\{vm_format_number(min)} - \{vm_format_number(max)}"
            (Some(min), None) => ">= \{vm_format_number(min)}"
            (None, Some(max)) => "<= \{vm_format_number(max)}"
            _ => ""
          }
      }
  }
}

///|
fn vm_split_number_text(
  min : Double,
  max : Double,
  index : Int,
  count : Int,
  is_first_open : Bool,
  is_last_open : Bool,
) -> String {
  if index == 0 {
    if is_first_open {
      "< \{vm_format_number(max)}"
    } else {
      "< \{vm_format_number(max)}"
    }
  } else if index == count - 1 {
    if is_last_open {
      "> \{vm_format_number(min)}"
    } else {
      "> \{vm_format_number(min)}"
    }
  } else {
    "\{vm_format_number(min)} - \{vm_format_number(max)}"
  }
}

///|
fn vm_is_piecewise(vm : @option.VisualMapOption) -> Bool {
  match vm.map_type {
    Some(type_name) if type_name == "piecewise" => true
    _ =>
      vm.pieces.length() > 0 ||
      vm.categories.length() > 0 ||
      vm.split_number > 0
  }
}

///|
fn vm_build_piecewise_items(
  vm : @option.VisualMapOption,
) -> Array[VmPiecewiseViewItem] {
  let item_w = vm.item_width.unwrap_or(20.0)
  let item_h = vm.item_height.unwrap_or(14.0)
  let char_w = 7.0
  let text_gap = 10.0
  let base_colors = vm_primary_colors(vm)
  let inactive_color = vm_inactive_color(vm)
  let show_ends = vm.text.length() >= 2
  let show_label = match vm.show_label {
    Some(v) => v
    None => !show_ends
  }
  let mut content_items : Array[VmPiecewiseViewItem] = []

  if vm.pieces.length() > 0 {
    for i, piece in vm.pieces {
      let text = vm_piece_text(piece)
      let selected = vm_selected_state(vm, i.to_string())
      let color = match piece.color {
        Some(c) if c != "" => c
        _ =>
          if base_colors.length() > 0 {
            let ratio = if vm.pieces.length() <= 1 {
              0.0
            } else {
              i.to_double() / (vm.pieces.length() - 1).to_double()
            }
            vm_color_at_ratio(base_colors, ratio)
          } else {
            "#5070dd"
          }
      }
      let symbol = match piece.symbol {
        Some(s) if s != "" => s
        _ => vm.item_symbol
      }
      content_items.push(
        vm_make_piecewise_item(
          text, color, symbol, selected, true, show_label, item_w, item_h, text_gap,
          char_w,
        ),
      )
    }
  } else if vm.categories.length() > 0 {
    for i, text in vm.categories {
      let selected = vm_selected_state(vm, text)
      let color = if base_colors.length() > 0 {
        let ratio = if vm.categories.length() <= 1 {
          0.0
        } else {
          i.to_double() / (vm.categories.length() - 1).to_double()
        }
        vm_color_at_ratio(base_colors, ratio)
      } else {
        "#5070dd"
      }
      content_items.push(
        vm_make_piecewise_item(
          text,
          color,
          vm.item_symbol,
          selected,
          true,
          show_label,
          item_w,
          item_h,
          text_gap,
          char_w,
        ),
      )
    }
  } else if vm.split_number > 0 {
    let split_number = if vm.split_number <= 0 { 1 } else { vm.split_number }
    let step = (vm.max - vm.min) / split_number.to_double()
    if vm.min_open {
      let item = vm_make_piecewise_item(
        "< \{vm_format_number(vm.min)}",
        if base_colors.length() > 0 {
          base_colors[0]
        } else {
          "#5070dd"
        },
        vm.item_symbol,
        vm_selected_state(vm, "min_open"),
        true,
        show_label,
        item_w,
        item_h,
        text_gap,
        char_w,
      )
      content_items.push(item)
    }
    let mut i = 0
    while i < split_number {
      let min = vm.min + step * i.to_double()
      let max = if i == split_number - 1 { vm.max } else { min + step }
      let text = vm_split_number_text(
        min,
        max,
        i,
        split_number,
        vm.min_open,
        vm.max_open,
      )
      let color = if base_colors.length() > 0 {
        let ratio = if split_number <= 1 {
          0.0
        } else {
          i.to_double() / (split_number - 1).to_double()
        }
        vm_color_at_ratio(base_colors, ratio)
      } else {
        "#5070dd"
      }
      let item = vm_make_piecewise_item(
        text,
        color,
        vm.item_symbol,
        vm_selected_state(vm, i.to_string()),
        true,
        show_label,
        item_w,
        item_h,
        text_gap,
        char_w,
      )
      content_items.push(item)
      i += 1
    }
    if vm.max_open {
      let item = vm_make_piecewise_item(
        "> \{vm_format_number(vm.max)}",
        if base_colors.length() > 0 {
          base_colors[base_colors.length() - 1]
        } else {
          "#5070dd"
        },
        vm.item_symbol,
        vm_selected_state(vm, "max_open"),
        true,
        show_label,
        item_w,
        item_h,
        text_gap,
        char_w,
      )
      content_items.push(item)
    }
  }

  let view_items : Array[VmPiecewiseViewItem] = []
  let mut ends_text = vm.text
  let reverse_view = if vm.orient == "horizontal" {
    vm.inverse
  } else {
    !vm.inverse
  }
  if reverse_view {
    content_items = vm_reverse_items(content_items)
  } else if show_ends {
    ends_text = vm_reverse_strings(ends_text)
  }

  if show_ends {
    let end_low = ends_text[0]
    let end_high = ends_text[1]
    view_items.push(
      vm_make_piecewise_item(
        end_low, inactive_color, "", true, false, true, item_w, item_h, text_gap,
        char_w,
      ),
    )
    view_items.append(content_items)
    view_items.push(
      vm_make_piecewise_item(
        end_high, inactive_color, "", true, false, true, item_w, item_h, text_gap,
        char_w,
      ),
    )
  } else {
    view_items.append(content_items)
  }

  view_items
}

///|
fn vm_render_piecewise_item(
  item : VmPiecewiseViewItem,
  item_align : String,
  show_label : Bool,
  label_color : String,
  font_size : Double,
  font_family : String,
  font_weight : String,
  item_w : Double,
  item_h : Double,
  text_gap : Double,
  inactive_color : String,
) -> @graphic.Element {
  let text_color = if item.selected { label_color } else { "#a0a4ab" }
  let fill_color = if item.selected { item.color } else { inactive_color }
  let children : Array[@graphic.Element] = []
  if item.show_symbol {
    children.push(
      @graphic.make_symbol(
        item.symbol,
        0.0,
        0.0,
        item_w,
        item_h,
        fill_color,
        1.0,
      ),
    )
  }
  if item.show_text {
    let (text_x, text_anchor) = if item.show_symbol {
      if item_align == "right" {
        (-text_gap, @graphic.TextAnchor::End)
      } else {
        (item_w + text_gap, @graphic.TextAnchor::Start)
      }
    } else if show_label {
      if item_align == "right" {
        (item_w, @graphic.TextAnchor::End)
      } else {
        (0.0, @graphic.TextAnchor::Start)
      }
    } else {
      (item_w / 2.0, @graphic.TextAnchor::Middle)
    }
    children.push(
      @graphic.Element::text_custom(
        text_x,
        item_h / 2.0,
        item.text,
        text_anchor,
        @graphic.TextBaseline::Central,
        text_color,
        font_size,
        font_family,
        font_weight,
      ),
    )
  }
  @graphic.Element::group(children)
}

///|
/// Render all visualMap components.
/// Continuous mode mirrors the current static gradient bar path.
/// Piecewise mode mirrors the explicit legend item ordering used by
/// `visualMap.piecewise` doc examples.
pub fn render_visual_map(opt : @option.ChartOption) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let width = opt.width
  let height = opt.height
  let padding = 15.0
  let text_gap = 10.0
  let default_label_color = "#54555a"
  let font_size = 12.0
  for vm in opt.visual_map {
    if !vm.show {
      continue
    }
    if vm_is_piecewise(vm) {
      let show_ends = vm.text.length() >= 2
      let show_label = match vm.show_label {
        Some(v) => v
        None => !show_ends
      }
      let item_w = vm.item_width.unwrap_or(20.0)
      let item_h = vm.item_height.unwrap_or(14.0)
      let item_gap = vm.item_gap
      let label_color = vm_label_color(vm, default_label_color)
      let text_font_size = vm_font_size(vm, font_size)
      let text_font_family = vm_font_family(vm, "sans-serif")
      let text_font_weight = vm_font_weight(vm, "normal")
      let inactive_color = vm_inactive_color(vm)
      let view_items = vm_build_piecewise_items(vm)
      let is_horizontal = vm.orient == "horizontal"
      let mut total_w = 0.0
      let mut total_h = 0.0

      for j, _ in view_items {
        let item = view_items[j]
        if is_horizontal {
          total_w = total_w + item.width
          if j > 0 {
            total_w = total_w + item_gap
          }
          if item.height > total_h {
            total_h = item.height
          }
        } else {
          total_h = total_h + item.height
          if j > 0 {
            total_h = total_h + item_gap
          }
          if item.width > total_w {
            total_w = item.width
          }
        }
      }
      let start_x = vm_resolve_start_x(
        vm.left,
        vm.right,
        width,
        total_w,
        padding,
      )
      let start_y = vm_resolve_start_y(
        vm.top,
        vm.bottom,
        height,
        total_h,
        padding,
      )
      let item_align = vm_resolve_item_align(vm, width, start_x, total_w)
      let mut cursor = 0.0
      for item in view_items {
        let child = vm_render_piecewise_item(
          item, item_align, show_label, label_color, text_font_size, text_font_family,
          text_font_weight, item_w, item_h, text_gap, inactive_color,
        )
        if is_horizontal {
          elems.push(
            @graphic.Element::group_transformed(
              [child],
              @graphic.Matrix::translate(start_x + cursor, start_y),
            ),
          )
          cursor = cursor + item.width + item_gap
        } else {
          elems.push(
            @graphic.Element::group_transformed(
              [child],
              @graphic.Matrix::translate(start_x, start_y + cursor),
            ),
          )
          cursor = cursor + item.height + item_gap
        }
      }
    } else {
      let item_w = vm.item_width.unwrap_or(20.0)
      let item_h = vm.item_height.unwrap_or(140.0)
      let is_horizontal = vm.orient == "horizontal"
      let bar_w = if is_horizontal { item_h } else { item_w }
      let bar_h = if is_horizontal { item_w } else { item_h }
      let colors = vm_primary_colors(vm)
      let bar_x = vm_resolve_start_x(vm.left, vm.right, width, bar_w, padding)
      let bar_y = match vm.top {
        Some(t) =>
          match t {
            "top" => padding + text_gap + font_size
            "middle" | "center" => (height - bar_h) * 0.5
            "bottom" => height - padding - bar_h
            _ => vm_parse_pos(t, height, 0.0) + padding + text_gap + font_size
          }
        None =>
          match vm.bottom {
            Some(b) => height - vm_parse_pos(b, height, 0.0) - padding - bar_h
            None => height - padding - bar_h
          }
      }
      vm_render_gradient_bar(
        elems, colors, bar_x, bar_y, bar_w, bar_h, is_horizontal,
      )
      elems.push(
        @graphic.Element::rect_outlined(
          bar_x, bar_y, bar_w, bar_h, "#b7b9be", 0.5,
        ),
      )
      let min_str = vm_format_number(vm.min)
      let max_str = vm_format_number(vm.max)
      if is_horizontal {
        let label_y = bar_y - text_gap
        elems.push(
          @graphic.Element::text_colored(
            bar_x,
            label_y,
            min_str,
            @graphic.TextAnchor::Start,
            @graphic.TextBaseline::Central,
            vm_label_color(vm, default_label_color),
          ),
        )
        elems.push(
          @graphic.Element::text_colored(
            bar_x + bar_w,
            label_y,
            max_str,
            @graphic.TextAnchor::End,
            @graphic.TextBaseline::Central,
            vm_label_color(vm, default_label_color),
          ),
        )
      } else {
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
            vm_label_color(vm, default_label_color),
          ),
        )
        elems.push(
          @graphic.Element::text_colored(
            center_x,
            min_label_y,
            min_str,
            @graphic.TextAnchor::Middle,
            @graphic.TextBaseline::Central,
            vm_label_color(vm, default_label_color),
          ),
        )
      }
      let top_text = vm_continuous_end_text(vm, 0)
      if top_text != "" {
        if is_horizontal {
          elems.push(
            @graphic.Element::text_colored(
              bar_x,
              bar_y - text_gap - font_size,
              top_text,
              @graphic.TextAnchor::Start,
              @graphic.TextBaseline::Central,
              vm_label_color(vm, default_label_color),
            ),
          )
        } else {
          elems.push(
            @graphic.Element::text_colored(
              bar_x + bar_w / 2.0,
              bar_y - text_gap - font_size,
              top_text,
              @graphic.TextAnchor::Middle,
              @graphic.TextBaseline::Central,
              vm_label_color(vm, default_label_color),
            ),
          )
        }
      }
      let bottom_text = vm_continuous_end_text(vm, 1)
      if bottom_text != "" {
        if is_horizontal {
          elems.push(
            @graphic.Element::text_colored(
              bar_x + bar_w,
              bar_y - text_gap - font_size,
              bottom_text,
              @graphic.TextAnchor::End,
              @graphic.TextBaseline::Central,
              vm_label_color(vm, default_label_color),
            ),
          )
        } else {
          elems.push(
            @graphic.Element::text_colored(
              bar_x + bar_w / 2.0,
              bar_y + bar_h + text_gap + font_size,
              bottom_text,
              @graphic.TextAnchor::Middle,
              @graphic.TextBaseline::Central,
              vm_label_color(vm, default_label_color),
            ),
          )
        }
      }
    }
  }
  elems
}
