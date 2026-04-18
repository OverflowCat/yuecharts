/// <=> echarts/src/chart/scatter/ScatterView.ts
//                  echarts/src/layout/points.ts
//                  echarts/src/component/visualMap/ContinuousModel.ts
//                  echarts/src/visual/VisualMapping.ts

///|
fn clamp01(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn geo_visual_map_for_series(
  opt : @option.ChartOption,
  series_index : Int,
) -> @option.VisualMapOption? {
  for i, _ in opt.visual_map {
    let visual_map = opt.visual_map[i]
    // None means "apply to all series"; Some(n) means only series n
    let matches = visual_map.series_index.map_or(true, idx => {
      idx == series_index
    })
    if matches {
      return Some(visual_map)
    }
  }
  None
}

///|
fn data_value_dimension(value : @option.DataValue, dimension : Int) -> Double? {
  match value {
    Num(n) => if dimension == 0 { Some(n) } else { None }
    Vec(arr) =>
      if dimension >= 0 && dimension < arr.length() {
        Some(arr[dimension])
      } else {
        None
      }
    DateValue(_, n) => if dimension == 1 { Some(n) } else { None }
    Null => None
  }
}

///|
fn geo_visual_map_ratio(
  visual_map : @option.VisualMapOption,
  item : @option.DataItem,
) -> Double? {
  data_value_dimension(item.value, visual_map.dimension).bind(value => {
    let span = visual_map.max - visual_map.min
    if span == 0.0 {
      Some(0.0)
    } else {
      Some(clamp01((value - visual_map.min) / span))
    }
  })
}

///|
fn color_stops_color(colors : Array[String], ratio : Double) -> String? {
  if colors.length() == 0 {
    return None
  }
  if colors.length() == 1 {
    return Some(colors[0])
  }
  let total = colors.length() - 1
  let scaled = clamp01(ratio) * total.to_double()
  let index = scaled.floor().to_int()
  let next_index = if index + 1 < colors.length() { index + 1 } else { index }
  let local_t = scaled - index.to_double()
  let start_color = @graphic.Color::from_string(colors[index]).unwrap_or(
    @graphic.black,
  )
  let end_color = @graphic.Color::from_string(colors[next_index]).unwrap_or(
    start_color,
  )
  Some(@graphic.Color::lerp(start_color, end_color, local_t).to_svg())
}

///|
fn geo_visual_map_symbol_size(
  opt : @option.ChartOption,
  series_index : Int,
  item : @option.DataItem,
  default_size : Double,
) -> Double {
  match geo_visual_map_for_series(opt, series_index) {
    Some(visual_map) =>
      geo_visual_map_ratio(visual_map, item)
      .map(ratio => {
        if visual_map.in_range.symbol_size.length() >= 2 {
          let min_size = visual_map.in_range.symbol_size[0]
          let max_size = visual_map.in_range.symbol_size[1]
          min_size + (max_size - min_size) * ratio
        } else {
          default_size
        }
      })
      .unwrap_or(default_size)
    None => default_size
  }
}

///|
/// <=> echarts/src/visual/VisualMapping.ts VisualMapping.mapValueToVisual (category branch)
fn geo_visual_map_color_category(
  visual_map : @option.VisualMapOption,
  item : @option.DataItem,
) -> String? {
  // For piecewise visualMap with categories: look up raw string value at the
  // specified dimension and find its index in categories array.
  let dim = visual_map.dimension
  let cat_str : String? = match item.raw_value_parts {
    Some(parts) if dim >= 0 && dim < parts.length() =>
      match parts[dim] {
        String(s) => Some(s)
        _ => None
      }
    _ => None
  }
  cat_str.bind(s => {
    let idx = visual_map.categories
      .iter()
      .mapi(fn(i, c) { (i, c) })
      .find_first(fn(pair) { pair.1 == s })
      .map(fn(pair) { pair.0 })
    idx.bind(i => {
      let colors = visual_map.in_range.color
      if i >= 0 && i < colors.length() {
        Some(colors[i])
      } else {
        None
      }
    })
  })
}

///|
fn geo_visual_map_color(
  opt : @option.ChartOption,
  series_index : Int,
  item : @option.DataItem,
) -> String? {
  geo_visual_map_for_series(opt, series_index).bind(visual_map => {
    // Piecewise category: use string dimension lookup instead of numeric ratio
    if visual_map.categories.length() > 0 {
      geo_visual_map_color_category(visual_map, item)
    } else {
      geo_visual_map_ratio(visual_map, item).bind(ratio => {
        color_stops_color(visual_map.in_range.color, ratio)
      })
    }
  })
}

///|
fn scatter_series_color(
  series : @option.SeriesOption,
  series_index : Int,
) -> String {
  match series.geo_item_style.bind(style => style.color) {
    Some(color) => color
    None => series.color.unwrap_or(@visual.palette_color(series_index))
  }
}

///|
fn scatter_point(
  series : @option.SeriesOption,
  data_index : Int,
  item : @option.DataItem,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
  calendar? : @coord.Calendar? = None,
  x_jitter? : Double = 0.0,
) -> @graphic.Point? {
  match (series.coordinate_system, polar, geo, calendar) {
    (Some("polar"), Some(p), _, _) =>
      match item.value {
        Null => None
        Num(n) =>
          Some(p.data_to_point(Num(n), Num(data_index.to_double()), data_index))
        Vec(arr) =>
          if arr.length() >= 2 {
            Some(p.data_to_point(Num(arr[0]), Num(arr[1]), data_index))
          } else if arr.length() == 1 {
            Some(
              p.data_to_point(
                Num(arr[0]),
                Num(data_index.to_double()),
                data_index,
              ),
            )
          } else {
            None
          }
        DateValue(_, n) =>
          Some(p.data_to_point(Num(n), Num(data_index.to_double()), data_index))
      }
    (Some("geo"), _, Some(g), _) =>
      match item.value {
        Vec(arr) =>
          if arr.length() >= 2 {
            Some(g.data_to_point(arr[0], arr[1]))
          } else {
            None
          }
        _ => None
      }
    (Some("calendar"), _, _, Some(c)) =>
      match item.value {
        DateValue(date, _) => {
          let point = c.data_to_point(date)
          if point.x == point.x && point.y == point.y {
            Some(point)
          } else {
            None
          }
        }
        _ =>
          match item.raw_value_parts {
            Some([String(date), ..]) => {
              let point = c.data_to_point(date)
              if point.x == point.x && point.y == point.y {
                Some(point)
              } else {
                None
              }
            }
            _ => None
          }
      }
    _ => {
      let x_idx = series.x_axis_index
      let y_idx = series.y_axis_index
      let nd = series.data.length()
      let nd_f = if nd > 0 { nd.to_double() } else { 1.0 }
      match item.value {
        Null => None
        Num(n) => {
          let px = if x_idx < coord.x_scales.length() {
            match coord.x_scales[x_idx] {
              Ordinal(s) => s.band_center(data_index)
              Linear(s) =>
                s.range_min +
                data_index.to_double() * (s.range_max - s.range_min) / nd_f
              BreakLinear(s) =>
                s.inner.range_min +
                data_index.to_double() *
                (s.inner.range_max - s.inner.range_min) /
                nd_f
            }
          } else {
            coord.bbox.x
          }
          let py = coord.num_y(y_idx, n)
          Some(@graphic.Point::new(px, py))
        }
        Vec(arr) =>
          if arr.length() >= 2 {
            let px = if x_idx < coord.x_scales.length() {
              match coord.x_scales[x_idx] {
                Ordinal(s) => {
                  let base = s.band_center(arr[0].to_int())
                  // Apply jitter offset when data has 3+ elements and jitter > 0
                  if arr.length() >= 3 && x_jitter > 0.0 {
                    base + (arr[2] - 0.5) * x_jitter
                  } else {
                    base
                  }
                }
                Linear(s) => s.data_to_pixel(arr[0])
                BreakLinear(s) => s.data_to_pixel(arr[0])
              }
            } else {
              coord.bbox.x
            }
            let py = coord.num_y(y_idx, arr[1])
            Some(@graphic.Point::new(px, py))
          } else if arr.length() == 1 {
            let px = if x_idx < coord.x_scales.length() {
              match coord.x_scales[x_idx] {
                Ordinal(s) => s.band_center(data_index)
                Linear(s) =>
                  s.range_min +
                  data_index.to_double() * (s.range_max - s.range_min) / nd_f
                BreakLinear(s) =>
                  s.inner.range_min +
                  data_index.to_double() *
                  (s.inner.range_max - s.inner.range_min) /
                  nd_f
              }
            } else {
              coord.bbox.x
            }
            let py = coord.num_y(y_idx, arr[0])
            Some(@graphic.Point::new(px, py))
          } else {
            None
          }
        DateValue(_, n) => {
          let px = if x_idx < coord.x_scales.length() {
            match coord.x_scales[x_idx] {
              Ordinal(s) => s.band_center(data_index)
              Linear(s) =>
                s.range_min +
                data_index.to_double() * (s.range_max - s.range_min) / nd_f
              BreakLinear(s) =>
                s.inner.range_min +
                data_index.to_double() *
                (s.inner.range_max - s.inner.range_min) /
                nd_f
            }
          } else {
            coord.bbox.x
          }
          let py = coord.num_y(y_idx, n)
          Some(@graphic.Point::new(px, py))
        }
      }
    }
  }
}

///|
pub fn render_scatter_series(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
  calendar? : @coord.Calendar? = None,
) -> Array[@graphic.Element] {
  let default_color = scatter_series_color(series, series_index)

  // Extract x-axis jitter pixel width (used by scatter jitter layout)
  let x_axis_idx = series.x_axis_index
  let x_jitter = if x_axis_idx < opt.x_axis.length() {
    opt.x_axis[x_axis_idx].jitter.unwrap_or(0.0)
  } else {
    0.0
  }
  // colorBy: "data" means each data item gets its own palette color by data index
  // Corresponds to: echarts/src/visual/style.ts dataColorPaletteTask
  let color_by_data = series.color_by == "data"

  // Check if any point is highlighted; if so apply emphasis/blur states to all points.
  let any_highlighted = @visual.has_any_highlighted(series.data)

  series.data
  .iter()
  .mapi(fn(di, item) {
    if scatter_point(
        series,
        di,
        item,
        coord,
        polar~,
        geo~,
        calendar~,
        x_jitter~,
      )
      is Some(point) {
      let series_default_color = if color_by_data {
        @visual.palette_color(di)
      } else {
        default_color
      }
      let color = geo_visual_map_color(opt, series_index, item).unwrap_or(
        series_default_color,
      )
      let symbol_size = geo_visual_map_symbol_size(
        opt,
        series_index,
        item,
        series.symbol_size,
      )
      let item_color = item.item_style.bind(s => s.color).unwrap_or(color)
      let item_opacity = item.item_style
        .bind(s => s.opacity)
        .unwrap_or(series.item_opacity.unwrap_or(0.8))
      let e = @graphic.Element::circle_colored_opacity(
        point.x,
        point.y,
        symbol_size * 0.5,
        item_color,
        item_opacity,
      )

      // Apply emphasis/blur states if any point is highlighted
      let result = if any_highlighted {
        let emphasis_fill = match item.highlighted {
          Some(true) => @visual.lift_hex_color(item_color)
          _ => item_color
        }
        let emphasis_style : @graphic.DisplayStateStyle = {
          fill: Some(emphasis_fill),
          stroke: None,
          line_width: None,
          stroke_no_scale: false,
        }
        let blur_style : @graphic.DisplayStateStyle = {
          fill: None,
          stroke: None,
          line_width: None,
          stroke_no_scale: false,
        }
        e.with_emphasis_style(emphasis_style).with_blur_style(blur_style)
      } else {
        e
      }
      Some(result)
    } else {
      None
    }
  })
  .filter_map(e => e)
  .collect()
}

///|
pub fn render_scatters(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  polars? : Array[@coord.Polar] = [],
  geo? : @coord.Geo? = None,
  calendar? : @coord.Calendar? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []

  for si, _ in opt.series {
    let series = opt.series[si]
    match series.series_type {
      Scatter => {
        // Select polar based on polarIndex
        let polar : @coord.Polar? = if series.coordinate_system == Some("polar") {
          let polar_idx = series.polar_index
          if polar_idx >= 0 && polar_idx < polars.length() {
            Some(polars[polar_idx])
          } else {
            None
          }
        } else {
          None
        }
        let series_elems = render_scatter_series(
          opt,
          series,
          si,
          coord,
          polar~,
          geo~,
          calendar~,
        )
        elems.append(series_elems)
      }
      _ => ()
    }
  }
  elems
}
