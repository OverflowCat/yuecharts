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
  let mut i = 0
  while i < opt.visual_map.length() {
    let visual_map = opt.visual_map[i]
    // None means "apply to all series"; Some(n) means only series n
    let matches = visual_map.series_index.map_or(true, idx => {
      idx == series_index
    })
    if matches {
      return Some(visual_map)
    }
    i += 1
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
fn geo_visual_map_color(
  opt : @option.ChartOption,
  series_index : Int,
  item : @option.DataItem,
) -> String? {
  geo_visual_map_for_series(opt, series_index).bind(visual_map => {
    geo_visual_map_ratio(visual_map, item).bind(ratio => {
      color_stops_color(visual_map.in_range.color, ratio)
    })
  })
}

///|
fn scatter_point(
  series : @option.SeriesOption,
  data_index : Int,
  item : @option.DataItem,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
) -> @graphic.Point? {
  match (series.coordinate_system, polar, geo) {
    (Some("polar"), Some(p), _) =>
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
    (Some("geo"), _, Some(g)) =>
      match item.value {
        Vec(arr) =>
          if arr.length() >= 2 {
            Some(g.data_to_point(arr[0], arr[1]))
          } else {
            None
          }
        _ => None
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
                Ordinal(s) => s.band_center(arr[0].to_int())
                Linear(s) => s.data_to_pixel(arr[0])
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
) -> Array[@graphic.Element] {
  let default_color = series.color.unwrap_or(
    @visual.palette_color(series_index),
  )
  series.data
  .iter()
  .mapi(fn(di, item) {
    if scatter_point(series, di, item, coord, polar~, geo~) is Some(point) {
      let color = geo_visual_map_color(opt, series_index, item).unwrap_or(
        default_color,
      )
      let symbol_size = geo_visual_map_symbol_size(
        opt,
        series_index,
        item,
        series.symbol_size,
      )
      let e = @graphic.Element::circle_colored(
        point.x,
        point.y,
        symbol_size * 0.5,
        color,
      )
      Some(e)
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
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    match series.series_type {
      Scatter => {
        let series_elems = render_scatter_series(
          opt,
          series,
          si,
          coord,
          polar~,
          geo~,
        )
        elems.append(series_elems)
      }
      _ => ()
    }
    si += 1
  }
  elems
}
