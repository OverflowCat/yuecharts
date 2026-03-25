// Corresponds to: echarts/src/chart/heatmap/HeatmapView.ts
//
// Cartesian heatmap: data format per item is Vec([x_index, y_index, value])
// where x_index and y_index are 0-based integer indices into the x/y categories.
// Color is driven by the `visualMap` option.
//
// ECharts default visualMap gradient (when no inRange.color is specified):
//   [lightThemeColor, themeColor] = [#d4dcf7, #5070dd]
//   lightThemeColor = modifyHSL('#5070dd', null, null, 0.9) ≈ rgb(212,220,247)
//   themeColor = '#5070dd' = rgb(80,112,221)
// See: echarts/src/model/globalDefault.ts  (gradientColor)
//      echarts/src/component/visualMap/VisualMapModel.ts

///|
/// Two-stop linear color from ECharts default visualMap gradient:
/// lightThemeColor (t=0) → themeColor (t=1).
/// This matches gradientColor = [modifyHSL('#5070dd',null,null,0.9), '#5070dd'].
fn visual_map_color(t : Double) -> @graphic.Color {
  // lightThemeColor = modifyHSL('#5070dd', null, null, 0.9) = rgb(212,220,247)
  let light = @graphic.Color::rgba(212, 220, 247, 255) // #d4dcf7
  // themeColor = '#5070dd' = rgb(80,112,221)
  let deep = @graphic.Color::rgba(80, 112, 221, 255) // #5070dd
  @graphic.Color::lerp(light, deep, t)
}

///|
/// Render a single heatmap series to scene graph elements.
/// `vm_min` / `vm_max` come from the visualMap option (or data range fallback).
pub fn render_heatmap_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  vm_min : Double,
  vm_max : Double,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let _ = series_index // color is driven by value, not palette index
  // Avoid division by zero for uniform value range
  let v_span = if vm_max > vm_min { vm_max - vm_min } else { 1.0 }
  // Cell size: ECharts heatmap uses getBandWidth() + 0.5 for each axis.
  // getBandWidth() is the ordinal band_step (no padding subtracted).
  // See: echarts/src/chart/heatmap/HeatmapView.ts:
  //   width  = xAxis.getBandWidth() + .5
  //   height = yAxis.getBandWidth() + .5
  let cell_w = if x_idx < coord.x_scales.length() {
    match coord.x_scales[x_idx] {
      Ordinal(s) => {
        let step = s.band_step()
        (if step < 0.0 { -step } else { step }) + 0.5
      }
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
      Ordinal(s) => {
        let step = s.band_step()
        (if step < 0.0 { -step } else { step }) + 0.5
      }
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
        let t = (v - vm_min) / v_span
        let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }
        let cell_color = visual_map_color(t_clamped)
        let color_str = cell_color.to_svg()
        // Cell is centered on the band_center of its [xi, yi] indices.
        // ECharts: point = coordSys.dataToPoint([xi, yi]), then draw rect
        //   at (point.x - width/2, point.y - height/2, width, height).
        let cx = if x_idx < coord.x_scales.length() {
          match coord.x_scales[x_idx] {
            Ordinal(s) => s.band_center(xi)
            Linear(s) => s.data_to_pixel(arr[0])
          }
        } else {
          coord.bbox.x + (xi.to_double() + 0.5) * cell_w
        }
        let cy = if y_idx < coord.y_scales.length() {
          match coord.y_scales[y_idx] {
            Ordinal(s) => s.band_center(yi)
            Linear(s) => s.data_to_pixel(arr[1])
          }
        } else {
          coord.bbox.y + (yi.to_double() + 0.5) * cell_h
        }
        let rx = cx - cell_w * 0.5
        let ry = cy - cell_h * 0.5
        elems.push(
          @graphic.Element::rect_colored(rx, ry, cell_w, cell_h, color_str),
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
  // Determine visualMap range: use explicit visualMap.min/max if present,
  // otherwise fall back to data range (first pass over all heatmap data).
  let (vm_min, vm_max) = match opt.visual_map {
    Some(vm) => (vm.min, vm.max)
    None => {
      // Compute from data
      let mut first = true
      let mut dmin = 0.0
      let mut dmax = 0.0
      let mut si = 0
      while si < opt.series.length() {
        let series = opt.series[si]
        si = si + 1
        match series.series_type {
          @option.Heatmap => {
            let mut di = 0
            while di < series.data.length() {
              let item = series.data[di]
              di = di + 1
              match item.value {
                Vec(arr) if arr.length() >= 3 => {
                  let v = arr[2]
                  if first {
                    dmin = v
                    dmax = v
                    first = false
                  } else {
                    if v < dmin {
                      dmin = v
                    }
                    if v > dmax {
                      dmax = v
                    }
                  }
                }
                _ => ()
              }
            }
          }
          _ => ()
        }
      }
      if first {
        (0.0, 1.0)
      } else {
        (dmin, dmax)
      }
    }
  }
  let mut si = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si = si + 1
    match series.series_type {
      Heatmap => {
        let series_elems = render_heatmap_series(
          series,
          si - 1,
          coord,
          vm_min,
          vm_max,
        )
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
