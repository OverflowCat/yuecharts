// Corresponds to: echarts/src/chart/heatmap/HeatmapView.ts
//
// Cartesian heatmap: data format per item is Vec([x_index, y_index, value])
// where x_index and y_index are 0-based integer indices into the x/y categories.
// Color is interpolated across a two-stop gradient based on normalised value.
//
// Default color stops (mirrors ECharts visualMap default spectral palette):
//   cold = "#313695"  hot = "#a50026"  mid = "#ffffbf"

///|
/// Three-stop thermal color: cold → mid → hot based on normalised t ∈ [0, 1].
/// Ref: ECharts default visualMap colormap.
fn thermal_color(t : Double) -> @graphic.Color {
  let cold = @graphic.Color::rgba(49, 54, 149, 255) // #313695
  let mid = @graphic.Color::rgba(255, 255, 191, 255) // #ffffbf
  let hot = @graphic.Color::rgba(165, 0, 38, 255) // #a50026
  if t <= 0.5 {
    @graphic.Color::lerp(cold, mid, t * 2.0)
  } else {
    @graphic.Color::lerp(mid, hot, (t - 0.5) * 2.0)
  }
}

///|
/// Render a single heatmap series to scene graph elements.
pub fn render_heatmap_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let _ = series_index // color is always driven by value, not palette index
  // First pass: find value range using first-valid-value initialisation
  let mut first = true
  let mut v_min = 0.0
  let mut v_max = 0.0
  let mut fi = 0
  while fi < series.data.length() {
    let item = series.data[fi]
    fi = fi + 1
    match item.value {
      Vec(arr) if arr.length() >= 3 => {
        let v = arr[2]
        if first {
          v_min = v
          v_max = v
          first = false
        } else {
          if v < v_min {
            v_min = v
          }
          if v > v_max {
            v_max = v
          }
        }
      }
      _ => ()
    }
  }
  if first {
    return elems // no valid data
  }
  // Avoid division by zero for uniform data
  let v_span = if v_max > v_min { v_max - v_min } else { 1.0 }
  // Second pass: render cells
  let cell_w = if x_idx < coord.x_scales.length() {
    match coord.x_scales[x_idx] {
      Ordinal(s) => s.band_width()
      Linear(s) => {
        let diff = s.range_max - s.range_min
        (if diff < 0.0 { -diff } else { diff }) / 10.0
      }
    }
  } else {
    10.0
  }
  let cell_h = if y_idx < coord.y_scales.length() {
    match coord.y_scales[y_idx] {
      Ordinal(s) => s.band_width()
      Linear(s) => {
        let diff = s.range_max - s.range_min
        (if diff < 0.0 { -diff } else { diff }) / 10.0
      }
    }
  } else {
    10.0
  }
  let mut di = 0
  while di < series.data.length() {
    let item = series.data[di]
    di = di + 1
    match item.value {
      Vec(arr) if arr.length() >= 3 => {
        let xi = arr[0].to_int()
        let yi = arr[1].to_int()
        let v = arr[2]
        let t = (v - v_min) / v_span
        let cell_color = thermal_color(t)
        let color_str = cell_color.to_svg()
        let px = if x_idx < coord.x_scales.length() {
          match coord.x_scales[x_idx] {
            Ordinal(s) => s.band_start(xi)
            Linear(s) => s.data_to_pixel(arr[0]) - cell_w * 0.5
          }
        } else {
          coord.bbox.x + xi.to_double() * cell_w
        }
        let py = if y_idx < coord.y_scales.length() {
          match coord.y_scales[y_idx] {
            Ordinal(s) => s.band_start(yi)
            Linear(s) => s.data_to_pixel(arr[1]) - cell_h * 0.5
          }
        } else {
          coord.bbox.y + yi.to_double() * cell_h
        }
        elems.push(
          @graphic.Element::rect_colored(px, py, cell_w, cell_h, color_str),
        )
      }
      _ => ()
    }
  }
  elems
}

///|
/// Render all heatmap series from a ChartOption to scene graph elements.
pub fn render_heatmaps(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si = si + 1
    match series.series_type {
      Heatmap => {
        let series_elems = render_heatmap_series(series, si - 1, coord)
        let mut ei = 0
        while ei < series_elems.length() {
          elems.push(series_elems[ei])
          ei = ei + 1
        }
      }
      _ => ()
    }
  }
  elems
}
