/// <=> echarts/src/chart/funnel/FunnelView.ts
/// <=> echarts/src/chart/funnel/funnelLayout.ts
//
// Funnel chart renderer.
//
// This follows the upstream box-layout funnel geometry:
// - each funnel series gets its own layout rect from left/top/right/bottom/width/height
// - data are sorted by `sort`
// - vertical orient uses width interpolation; horizontal orient uses height interpolation
// - `funnelAlign` controls the trapezoid anchor within the layout rect

///|
fn funnel_parse_size_like(value : String, reference : Double) -> Double {
  if value.has_suffix("%") {
    let pct_str = value[:value.length() - 1].to_string()
    let parsed = try? @string.parse_double(pct_str)
    match parsed {
      Ok(pct) => reference * pct / 100.0
      Err(_) => 0.0
    }
  } else {
    let parsed = try? @string.parse_double(value)
    match parsed {
      Ok(px) => px
      Err(_) => 0.0
    }
  }
}

///|
fn funnel_series_layout_bbox(
  series : @option.SeriesOption,
  chart_width : Double,
  chart_height : Double,
) -> @graphic.BBox {
  let grid : @option.GridOption = {
    left: series.left.unwrap_or("80"),
    right: series.right.unwrap_or("80"),
    top: series.top.unwrap_or("60"),
    bottom: series.bottom.unwrap_or("65"),
    width: series.width,
    height: series.height,
    contain_label: false,
  }
  @layout.compute_grid_bbox(grid, chart_width, chart_height)
}

///|
fn funnel_data_value(item : @option.DataItem) -> Double {
  match item.value {
    Num(n) => n
    Vec(arr) => if arr.length() > 0 { arr[0] } else { 0.0 }
    DateValue(_, n) => n
    Null => 0.0
  }
}

///|
fn funnel_data_extent(data : Array[@option.DataItem]) -> (Double, Double) {
  if data.length() == 0 {
    return (0.0, 0.0)
  }
  let mut lo = funnel_data_value(data[0])
  let mut hi = lo
  let mut i = 1
  while i < data.length() {
    let v = funnel_data_value(data[i])
    if v < lo {
      lo = v
    }
    if v > hi {
      hi = v
    }
    i += 1
  }
  (lo, hi)
}

///|
fn funnel_sorted_indices(
  data : Array[@option.DataItem],
  sort : String,
) -> Array[Int] {
  let indices : Array[Int] = []
  for i, _ in data {
    indices.push(i)
  }
  if sort == "none" {
    return indices
  }
  let mut a = 1
  while a < indices.length() {
    let key = indices[a]
    let key_value = funnel_data_value(data[key])
    let mut b = a
    while b > 0 {
      let prev = indices[b - 1]
      let prev_value = funnel_data_value(data[prev])
      let should_swap = if sort == "ascending" {
        prev_value > key_value
      } else {
        prev_value < key_value
      }
      if !should_swap {
        break
      }
      indices[b] = prev
      b -= 1
    }
    indices[b] = key
    a += 1
  }
  indices
}

///|
fn funnel_series_fill_color(
  series : @option.SeriesOption,
  index : Int,
) -> String {
  match series.geo_item_style {
    Some(style) =>
      match style.color {
        Some(color) => color
        None =>
          match series.item_style {
            Some(color) => color
            None =>
              match series.color {
                Some(color) => color
                None => @visual.palette_color(index)
              }
          }
      }
    None =>
      match series.item_style {
        Some(color) => color
        None =>
          match series.color {
            Some(color) => color
            None => @visual.palette_color(index)
          }
      }
  }
}

///|
fn funnel_item_fill_color(
  series : @option.SeriesOption,
  item : @option.DataItem,
  index : Int,
) -> String {
  match item.item_style {
    Some(style) =>
      match style.color {
        Some(color) => color
        None =>
          match style.area_color {
            Some(color) => color
            None => funnel_series_fill_color(series, index)
          }
      }
    None => funnel_series_fill_color(series, index)
  }
}

///|
fn funnel_item_border_color(
  series : @option.SeriesOption,
  item : @option.DataItem,
) -> String {
  match item.item_style {
    Some(style) =>
      match style.border_color {
        Some(color) => color
        None =>
          match series.geo_item_style {
            Some(series_style) => series_style.border_color.unwrap_or("#ffffff")
            None => "#ffffff"
          }
      }
    None =>
      match series.geo_item_style {
        Some(series_style) => series_style.border_color.unwrap_or("#ffffff")
        None => "#ffffff"
      }
  }
}

///|
fn funnel_item_border_width(
  series : @option.SeriesOption,
  item : @option.DataItem,
) -> Double {
  match item.item_style {
    Some(style) =>
      match style.border_width {
        Some(width) => width
        None =>
          match series.geo_item_style {
            Some(series_style) => series_style.border_width.unwrap_or(1.0)
            None => 1.0
          }
      }
    None =>
      match series.geo_item_style {
        Some(series_style) => series_style.border_width.unwrap_or(1.0)
        None => 1.0
      }
  }
}

///|
fn funnel_item_opacity(
  series : @option.SeriesOption,
  item : @option.DataItem,
) -> Double {
  match item.item_style {
    Some(style) =>
      match style.opacity {
        Some(opacity) => opacity
        None =>
          match series.geo_item_style {
            Some(series_style) => series_style.opacity.unwrap_or(1.0)
            None => 1.0
          }
      }
    None =>
      match series.geo_item_style {
        Some(series_style) => series_style.opacity.unwrap_or(1.0)
        None => 1.0
      }
  }
}

///|
fn funnel_label_show(
  series : @option.SeriesOption,
  item : @option.DataItem,
) -> Bool {
  match item.label {
    Some(label) => label.show.unwrap_or(series.label.map_or(false, l => l.show))
    None => series.label.map_or(false, l => l.show)
  }
}

///|
fn funnel_label_position(
  series : @option.SeriesOption,
  item : @option.DataItem,
) -> String {
  match item.label {
    Some(label) =>
      match label.position {
        Some(position) => position
        None => series.label.map_or("outer", l => l.position.unwrap_or("outer"))
      }
    None => series.label.map_or("outer", l => l.position.unwrap_or("outer"))
  }
}

///|
fn funnel_label_distance(
  series : @option.SeriesOption,
  item : @option.DataItem,
) -> Double {
  match item.label {
    Some(label) =>
      match label.distance {
        Some(distance) => distance
        None => series.label.map_or(5.0, l => l.distance.unwrap_or(5.0))
      }
    None => series.label.map_or(5.0, l => l.distance.unwrap_or(5.0))
  }
}

///|
fn funnel_label_color(
  series : @option.SeriesOption,
  item : @option.DataItem,
  fallback : String,
) -> String {
  let color = match item.label {
    Some(label) =>
      match label.color {
        Some(c) => c
        None => series.label.map_or(fallback, l => l.color)
      }
    None => series.label.map_or(fallback, l => l.color)
  }
  if color == "inherit" {
    fallback
  } else {
    color
  }
}

///|
priv struct FunnelLabelLayout {
  line_points : Array[@graphic.Point]
  x : Double
  y : Double
  anchor : @graphic.TextAnchor
  baseline : @graphic.TextBaseline
  inside : Bool
}

///|
fn funnel_label_layout(
  series : @option.SeriesOption,
  item : @option.DataItem,
  points : Array[@graphic.Point],
  orient : String,
) -> FunnelLabelLayout {
  let position = funnel_label_position(series, item)
  let distance = funnel_label_distance(series, item)
  let line_len = 20.0
  let left_x = (points[0].x + points[3].x) / 2.0
  let right_x = (points[1].x + points[2].x) / 2.0
  let top_y = (points[0].y + points[1].y) / 2.0
  let bottom_y = (points[2].y + points[3].y) / 2.0
  let center_x = (points[0].x + points[1].x + points[2].x + points[3].x) / 4.0
  let center_y = (points[0].y + points[1].y + points[2].y + points[3].y) / 4.0

  if position == "inner" ||
    position == "inside" ||
    position == "center" ||
    position == "insideLeft" ||
    position == "insideRight" {
    let mut x = center_x
    let mut anchor = @graphic.TextAnchor::Middle
    if position == "insideLeft" {
      x = left_x + 5.0
      anchor = @graphic.TextAnchor::Start
    } else if position == "insideRight" {
      x = right_x - 5.0
      anchor = @graphic.TextAnchor::End
    }
    return {
      line_points: [
        @graphic.Point::new(x, center_y),
        @graphic.Point::new(x, center_y),
      ],
      x,
      y: center_y,
      anchor,
      baseline: @graphic.TextBaseline::Central,
      inside: true,
    }
  }

  if orient == "horizontal" {
    if position == "top" || position == "leftTop" || position == "rightTop" {
      let text_y = top_y - line_len - distance
      return {
        line_points: [
          @graphic.Point::new(center_x, top_y),
          @graphic.Point::new(center_x, top_y - line_len),
        ],
        x: center_x,
        y: text_y,
        anchor: @graphic.TextAnchor::Middle,
        baseline: @graphic.TextBaseline::Central,
        inside: false,
      }
    }
    let text_y = bottom_y + line_len + distance
    return {
      line_points: [
        @graphic.Point::new(center_x, bottom_y),
        @graphic.Point::new(center_x, bottom_y + line_len),
      ],
      x: center_x,
      y: text_y,
      anchor: @graphic.TextAnchor::Middle,
      baseline: @graphic.TextBaseline::Central,
      inside: false,
    }
  }

  if position == "left" || position == "leftTop" || position == "leftBottom" {
    let text_x = left_x - line_len - distance
    return {
      line_points: [
        @graphic.Point::new(left_x, center_y),
        @graphic.Point::new(left_x - line_len, center_y),
      ],
      x: text_x,
      y: center_y,
      anchor: @graphic.TextAnchor::End,
      baseline: @graphic.TextBaseline::Central,
      inside: false,
    }
  }

  if position == "top" {
    let text_y = top_y - line_len - distance
    return {
      line_points: [
        @graphic.Point::new(center_x, top_y),
        @graphic.Point::new(center_x, top_y - line_len),
      ],
      x: center_x,
      y: text_y,
      anchor: @graphic.TextAnchor::Middle,
      baseline: @graphic.TextBaseline::Central,
      inside: false,
    }
  }

  if position == "bottom" {
    let text_y = bottom_y + line_len + distance
    return {
      line_points: [
        @graphic.Point::new(center_x, bottom_y),
        @graphic.Point::new(center_x, bottom_y + line_len),
      ],
      x: center_x,
      y: text_y,
      anchor: @graphic.TextAnchor::Middle,
      baseline: @graphic.TextBaseline::Central,
      inside: false,
    }
  }

  let text_x = right_x + line_len + distance
  {
    line_points: [
      @graphic.Point::new(right_x, center_y),
      @graphic.Point::new(right_x + line_len, center_y),
    ],
    x: text_x,
    y: center_y,
    anchor: @graphic.TextAnchor::Start,
    baseline: @graphic.TextBaseline::Central,
    inside: false,
  }
}

///|
fn funnel_line_points(
  series : @option.SeriesOption,
  idx : Int,
  min_val : Double,
  max_val : Double,
  size_extent_lo : Double,
  size_extent_hi : Double,
  offset : Double,
  orient : String,
  align : String,
  box_x : Double,
  box_y : Double,
  box_w : Double,
  box_h : Double,
) -> Array[@graphic.Point] {
  let value = if idx >= 0 && idx < series.data.length() {
    funnel_data_value(series.data[idx])
  } else {
    0.0
  }
  let size = linear_map(value, min_val, max_val, size_extent_lo, size_extent_hi)
  if orient == "horizontal" {
    let y0 = if align == "top" {
      box_y
    } else if align == "bottom" {
      box_y + box_h - size
    } else {
      box_y + (box_h - size) / 2.0
    }
    [@graphic.Point::new(offset, y0), @graphic.Point::new(offset, y0 + size)]
  } else {
    let x0 = if align == "left" {
      box_x
    } else if align == "right" {
      box_x + box_w - size
    } else {
      box_x + (box_w - size) / 2.0
    }
    [@graphic.Point::new(x0, offset), @graphic.Point::new(x0 + size, offset)]
  }
}

///|
fn linear_map(
  value : Double,
  src_lo : Double,
  src_hi : Double,
  dst_lo : Double,
  dst_hi : Double,
) -> Double {
  if src_hi <= src_lo {
    return dst_lo
  }
  let t = (value - src_lo) / (src_hi - src_lo)
  let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
  dst_lo + t_clamped * (dst_hi - dst_lo)
}

///|
/// Render all funnel series.
pub fn render_funnels(
  opt : @option.ChartOption,
  _coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut series_index = 0
  for i, _ in opt.series {
    let series = opt.series[i]
    match series.series_type {
      Funnel => {
        let series_elems = render_funnel_series(
          series,
          series_index,
          opt.width,
          opt.height,
        )
        elems.append(series_elems)
      }
      _ => ()
    }
    series_index += 1
  }
  elems
}

///|
/// Render a single funnel series.
pub fn render_funnel_series(
  series : @option.SeriesOption,
  _series_index : Int,
  chart_width : Double,
  chart_height : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let nd = series.data.length()
  if nd == 0 {
    return elems
  }

  let bbox = funnel_series_layout_bbox(series, chart_width, chart_height)
  let box_x = bbox.x
  let box_y = bbox.y
  let box_w = bbox.width
  let box_h = bbox.height
  let orient = series.funnel_orient
  let align = series.funnel_align
  let sort = series.funnel_sort
  let view_size = if orient == "horizontal" { box_w } else { box_h }
  let mut gap = series.funnel_gap

  let indices0 = funnel_sorted_indices(series.data, sort)
  let indices = if sort == "ascending" { indices0.rev() } else { indices0 }

  let (data_min, data_max) = funnel_data_extent(series.data)
  let min_val = series.funnel_min.unwrap_or(
    if data_min < 0.0 {
      data_min
    } else {
      0.0
    },
  )
  let max_val = series.funnel_max.unwrap_or(data_max)
  let size_extent_lo = if orient == "horizontal" {
    funnel_parse_size_like(series.funnel_min_size, box_h)
  } else {
    funnel_parse_size_like(series.funnel_min_size, box_w)
  }
  let size_extent_hi = if orient == "horizontal" {
    funnel_parse_size_like(series.funnel_max_size, box_h)
  } else {
    funnel_parse_size_like(series.funnel_max_size, box_w)
  }

  let mut item_size = (view_size - gap * (nd - 1).to_double()) / nd.to_double()
  let mut cursor = if sort == "ascending" {
    if orient == "horizontal" {
      box_x + box_w
    } else {
      box_y + box_h
    }
  } else if orient == "horizontal" {
    box_x
  } else {
    box_y
  }
  if sort == "ascending" {
    item_size = -item_size
    gap = -gap
  }

  for i, _ in indices {
    let idx = indices[i]
    let next_idx = if i + 1 < indices.length() {
      indices[i + 1]
    } else {
      series.data.length()
    }
    let item = series.data[idx]

    let start = funnel_line_points(
      series, idx, min_val, max_val, size_extent_lo, size_extent_hi, cursor, orient,
      align, box_x, box_y, box_w, box_h,
    )
    let end = funnel_line_points(
      series,
      next_idx,
      min_val,
      max_val,
      size_extent_lo,
      size_extent_hi,
      cursor + item_size,
      orient,
      align,
      box_x,
      box_y,
      box_w,
      box_h,
    )

    let points = [start[0], start[1], end[1], end[0]]
    let fill_color = funnel_item_fill_color(series, item, idx)
    let border_color = funnel_item_border_color(series, item)
    let border_width = funnel_item_border_width(series, item)
    let opacity = funnel_item_opacity(series, item)
    elems.push(
      @graphic.Element::polygon_fill_stroke(
        points,
        @graphic.Color::from_string(fill_color).unwrap_or(@graphic.black),
        @graphic.Color::from_string(border_color).unwrap_or(@graphic.white),
        border_width,
        opacity,
      ),
    )

    if funnel_label_show(series, item) {
      let label_text = item.name.unwrap_or("")
      if label_text != "" {
        let label_color = funnel_label_color(series, item, fill_color)
        let layout = funnel_label_layout(series, item, points, orient)
        if !layout.inside && series.label_line_show {
          elems.push(
            @graphic.Element::polyline_leader(layout.line_points, fill_color),
          )
        }
        elems.push(
          @graphic.Element::text_colored(
            layout.x,
            layout.y,
            label_text,
            layout.anchor,
            layout.baseline,
            if label_color == "inherit" {
              fill_color
            } else {
              label_color
            },
          ),
        )
      }
    }

    cursor += item_size + gap
  }

  elems
}
