/// <=> echarts/src/chart/boxplot/BoxplotView.ts
/// <=> echarts/src/chart/boxplot/boxplotLayout.ts

///|
/// <=> echarts/src/chart/helper/whiskerBoxCommon.ts:getWhiskerBoxLayout
fn boxplot_is_horizontal(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
) -> Bool {
  let x_cat = series.x_axis_index >= 0 &&
    series.x_axis_index < opt.x_axis.length() &&
    opt.x_axis[series.x_axis_index].axis_type == @option.AxisType::Category
  let y_cat = series.y_axis_index >= 0 &&
    series.y_axis_index < opt.y_axis.length() &&
    opt.y_axis[series.y_axis_index].axis_type == @option.AxisType::Category
  if x_cat && !y_cat {
    false
  } else if y_cat && !x_cat {
    true
  } else {
    false
  }
}

///|
fn boxplot_base_axis_index(
  series : @option.SeriesOption,
  horizontal : Bool,
) -> Int {
  if horizontal {
    series.y_axis_index
  } else {
    series.x_axis_index
  }
}

///|
fn boxplot_base_band_width(
  coord : @coord.Cartesian2D,
  horizontal : Bool,
  base_axis_index : Int,
  max_data_count : Int,
) -> Double {
  if horizontal {
    if base_axis_index >= 0 && base_axis_index < coord.y_scales.length() {
      match coord.y_scales[base_axis_index] {
        Ordinal(s) => s.band_width()
        Linear(s) =>
          (s.range_max - s.range_min).abs() / max_data_count.to_double()
        BreakLinear(s) =>
          (s.inner.range_max - s.inner.range_min).abs() /
          max_data_count.to_double()
      }
    } else {
      8.0
    }
  } else if base_axis_index >= 0 && base_axis_index < coord.x_scales.length() {
    match coord.x_scales[base_axis_index] {
      Ordinal(s) => s.band_width()
      Linear(s) =>
        (s.range_max - s.range_min).abs() / max_data_count.to_double()
      BreakLinear(s) =>
        (s.inner.range_max - s.inner.range_min).abs() /
        max_data_count.to_double()
    }
  } else {
    8.0
  }
}

///|
/// <=> echarts/src/chart/boxplot/boxplotLayout.ts:calculateBase
fn boxplot_group_offsets(
  band_width : Double,
  series_count : Int,
) -> (Array[Double], Array[Double]) {
  let box_offsets : Array[Double] = []
  let box_widths : Array[Double] = []
  if series_count <= 0 {
    return (box_offsets, box_widths)
  }
  let available_width = band_width * 0.8 - 2.0
  let box_gap = available_width / series_count.to_double() * 0.3
  let box_width = (available_width - box_gap * (series_count - 1).to_double()) /
    series_count.to_double()
  let mut base = box_width / 2.0 - available_width / 2.0
  let mut i = 0
  while i < series_count {
    box_offsets.push(base)
    base += box_gap + box_width
    box_widths.push(boxplot_min(boxplot_max(box_width, 7.0), 50.0))
    i += 1
  }
  (box_offsets, box_widths)
}

///|
fn boxplot_min(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn boxplot_max(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// <=> echarts/src/chart/boxplot/boxplotLayout.ts:layoutSingleSeries
fn boxplot_data_values(
  item : @option.DataItem,
) -> (Double, Double, Double, Double, Double)? {
  match item.value {
    Vec(arr) if arr.length() >= 6 =>
      Some((arr[1], arr[2], arr[3], arr[4], arr[5]))
    Vec(arr) if arr.length() >= 5 =>
      Some((arr[0], arr[1], arr[2], arr[3], arr[4]))
    _ => None
  }
}

///|
fn boxplot_base_center(
  coord : @coord.Cartesian2D,
  horizontal : Bool,
  base_axis_index : Int,
  data_index : Int,
) -> Double {
  if horizontal {
    if base_axis_index >= 0 && base_axis_index < coord.y_scales.length() {
      match coord.y_scales[base_axis_index] {
        Ordinal(s) => s.band_center(data_index)
        Linear(s) => s.data_to_pixel(data_index.to_double())
        BreakLinear(s) => s.data_to_pixel(data_index.to_double())
      }
    } else {
      coord.bbox.y
    }
  } else if base_axis_index >= 0 && base_axis_index < coord.x_scales.length() {
    match coord.x_scales[base_axis_index] {
      Ordinal(s) => s.band_center(data_index)
      Linear(s) => s.data_to_pixel(data_index.to_double())
      BreakLinear(s) => s.data_to_pixel(data_index.to_double())
    }
  } else {
    coord.bbox.x
  }
}

///|
fn boxplot_push_segment(
  elems : Array[@graphic.Element],
  any_highlighted : Bool,
  emphasis_style : @graphic.DisplayStateStyle,
  blur_style : @graphic.DisplayStateStyle,
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
  color : String,
  line_w : Double,
) -> Unit {
  let line = @graphic.Element::line_colored(x0, y0, x1, y1, color, line_w)
  elems.push(
    if any_highlighted {
      line.with_emphasis_style(emphasis_style).with_blur_style(blur_style)
    } else {
      line
    },
  )
}

///|
/// <=> echarts/src/chart/boxplot/BoxplotView.ts:createNormalBox
/// <=> echarts/src/chart/boxplot/boxplotLayout.ts:layoutSingleSeries
fn render_boxplot_series(
  series : @option.SeriesOption,
  series_color_index : Int,
  coord : @coord.Cartesian2D,
  horizontal : Bool,
  offset : Double,
  box_width : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let color = series.color.unwrap_or(@visual.palette_color(series_color_index))
  let any_highlighted = @visual.has_any_highlighted(series.data)
  let emphasis_style : @graphic.DisplayStateStyle = {
    fill: None,
    stroke: Some(@visual.lift_hex_color(color)),
    line_width: None,
    stroke_no_scale: false,
  }
  let blur_style : @graphic.DisplayStateStyle = {
    fill: None,
    stroke: None,
    line_width: None,
    stroke_no_scale: false,
  }
  let line_w = series.geo_item_style.bind(s => s.border_width).unwrap_or(1.5)
  let half_w = box_width * 0.5
  let cap_half_w = box_width * 0.25
  let base_axis_index = boxplot_base_axis_index(series, horizontal)

  let nd = series.data.length()
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    match boxplot_data_values(item) {
      Some((v_min, q1, med, q3, v_max)) => {
        let base_center = boxplot_base_center(
            coord, horizontal, base_axis_index, di,
          ) +
          offset
        if horizontal {
          let x_min = coord.num_x(series.x_axis_index, v_min)
          let x_q1 = coord.num_x(series.x_axis_index, q1)
          let x_med = coord.num_x(series.x_axis_index, med)
          let x_q3 = coord.num_x(series.x_axis_index, q3)
          let x_max = coord.num_x(series.x_axis_index, v_max)
          let left = boxplot_min(x_q1, x_q3)
          let right = boxplot_max(x_q1, x_q3)
          let top = base_center - half_w
          let bottom = base_center + half_w
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, left, top, right,
            top, color, line_w,
          )
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, left, bottom, right,
            bottom, color, line_w,
          )
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, left, top, left,
            bottom, color, line_w,
          )
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, right, top, right,
            bottom, color, line_w,
          )
          boxplot_push_segment(
            elems,
            any_highlighted,
            emphasis_style,
            blur_style,
            x_med,
            top,
            x_med,
            bottom,
            color,
            line_w * 1.333,
          )
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, x_min, base_center,
            left, base_center, color, 1.0,
          )
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, right, base_center,
            x_max, base_center, color, 1.0,
          )
          boxplot_push_segment(
            elems,
            any_highlighted,
            emphasis_style,
            blur_style,
            x_min,
            base_center - cap_half_w,
            x_min,
            base_center + cap_half_w,
            color,
            1.0,
          )
          boxplot_push_segment(
            elems,
            any_highlighted,
            emphasis_style,
            blur_style,
            x_max,
            base_center - cap_half_w,
            x_max,
            base_center + cap_half_w,
            color,
            1.0,
          )
        } else {
          let y_min = coord.num_y(series.y_axis_index, v_min)
          let y_q1 = coord.num_y(series.y_axis_index, q1)
          let y_med = coord.num_y(series.y_axis_index, med)
          let y_q3 = coord.num_y(series.y_axis_index, q3)
          let y_max = coord.num_y(series.y_axis_index, v_max)
          let top = boxplot_min(y_q1, y_q3)
          let bottom = boxplot_max(y_q1, y_q3)
          let left = base_center - half_w
          let right = base_center + half_w
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, left, top, right,
            top, color, line_w,
          )
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, left, bottom, right,
            bottom, color, line_w,
          )
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, left, top, left,
            bottom, color, line_w,
          )
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, right, top, right,
            bottom, color, line_w,
          )
          boxplot_push_segment(
            elems,
            any_highlighted,
            emphasis_style,
            blur_style,
            left,
            y_med,
            right,
            y_med,
            color,
            line_w * 1.333,
          )
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, base_center, y_max,
            base_center, top, color, 1.0,
          )
          boxplot_push_segment(
            elems, any_highlighted, emphasis_style, blur_style, base_center, bottom,
            base_center, y_min, color, 1.0,
          )
          boxplot_push_segment(
            elems,
            any_highlighted,
            emphasis_style,
            blur_style,
            base_center - cap_half_w,
            y_max,
            base_center + cap_half_w,
            y_max,
            color,
            1.0,
          )
          boxplot_push_segment(
            elems,
            any_highlighted,
            emphasis_style,
            blur_style,
            base_center - cap_half_w,
            y_min,
            base_center + cap_half_w,
            y_min,
            color,
            1.0,
          )
        }
      }
      None => ()
    }
    di += 1
  }
  elems
}

///|
/// <=> echarts/src/chart/boxplot/boxplotLayout.ts:groupSeriesByAxis
/// <=> echarts/src/chart/boxplot/boxplotLayout.ts:calculateBase
pub fn render_boxplots(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let group_series_indices : Array[Array[Int]] = []
  let group_base_axis : Array[Int] = []
  let group_horizontal : Array[Bool] = []

  for si, _ in opt.series {
    let series = opt.series[si]
    if series.series_type != Boxplot {
      continue
    }
    let horizontal = boxplot_is_horizontal(opt, series)
    let base_axis_index = boxplot_base_axis_index(series, horizontal)
    let mut gi = 0
    let mut found = -1
    while gi < group_series_indices.length() {
      if group_base_axis[gi] == base_axis_index &&
        group_horizontal[gi] == horizontal {
        found = gi
        break
      }
      gi += 1
    }
    if found < 0 {
      group_base_axis.push(base_axis_index)
      group_horizontal.push(horizontal)
      group_series_indices.push([si])
    } else {
      group_series_indices[found].push(si)
    }
  }

  for gi, _ in group_series_indices {
    let series_indices = group_series_indices[gi]
    if series_indices.is_empty() {
      continue
    }
    let mut max_data_count = 1
    for si in series_indices {
      if opt.series[si].data.length() > max_data_count {
        max_data_count = opt.series[si].data.length()
      }
    }
    let horizontal = group_horizontal[gi]
    let base_axis_index = group_base_axis[gi]
    let band_width = boxplot_base_band_width(
      coord, horizontal, base_axis_index, max_data_count,
    )
    let (offsets, widths) = boxplot_group_offsets(
      band_width,
      series_indices.length(),
    )
    let mut local_idx = 0
    while local_idx < series_indices.length() {
      let si = series_indices[local_idx]
      elems.append(
        render_boxplot_series(
          opt.series[si],
          si,
          coord,
          horizontal,
          offsets[local_idx],
          widths[local_idx],
        ),
      )
      local_idx += 1
    }
  }
  elems
}
