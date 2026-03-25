// Corresponds to: echarts/src/chart/effectScatter/EffectScatterSeries.ts
//                  echarts/src/chart/effectScatter/EffectScatterView.ts
//                  echarts/src/chart/effectScatter/install.ts
//                  echarts/src/layout/points.ts
//                  echarts/src/chart/helper/EffectSymbol.ts

///|
fn effect_scatter_point(
  series : @option.SeriesOption,
  data_index : Int,
  item : @option.DataItem,
  coord : @coord.Cartesian2D,
) -> (Double, Double)? {
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
      Some((px, py))
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
        Some((px, py))
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
        Some((px, py))
      } else {
        None
      }
  }
}

///|
fn render_effect_ripple(
  elems : Array[@graphic.Element],
  px : Double,
  py : Double,
  color : String,
  symbol_radius : Double,
) -> Unit {
  // Static SVG snapshot of EffectSymbol's animated ripple:
  // default rippleEffect.scale = 2.5, brushType = 'fill', number = 3.
  let ripple_scales = [2.5, 1.8333333333333333, 1.1666666666666667]
  let ripple_opacities = [0.0, 0.33333333333333337, 0.6666666666666667]
  let mut i = 0
  while i < ripple_scales.length() {
    elems.push(
      @graphic.Element::circle_colored_opacity(
        px,
        py,
        symbol_radius * ripple_scales[i],
        color,
        ripple_opacities[i],
      ),
    )
    i = i + 1
  }
}

///|
/// Render an EffectScatterSeries to scene graph elements.
pub fn render_effect_scatter_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let color = match series.color {
    Some(c) => c
    None => @visual.palette_color(series_index)
  }
  let symbol_radius = series.symbol_size * 0.5
  let mut di = 0
  while di < series.data.length() {
    let item = series.data[di]
    match effect_scatter_point(series, di, item, coord) {
      Some((px, py)) => {
        render_effect_ripple(elems, px, py, color, symbol_radius)
        elems.push(
          @graphic.Element::circle_colored(px, py, symbol_radius, color),
        )
      }
      None => ()
    }
    di = di + 1
  }
  elems
}

///|
/// Render all effectScatter series from a ChartOption to scene graph elements.
pub fn render_effect_scatters(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut si = 0
  let mut color_idx = 0
  while si < opt.series.length() {
    let series = opt.series[si]
    si = si + 1
    match series.series_type {
      EffectScatter => ()
      _ => {
        color_idx = color_idx + 1
        continue
      }
    }
    let series_elems = render_effect_scatter_series(series, color_idx, coord)
    let mut ei = 0
    while ei < series_elems.length() {
      elems.push(series_elems[ei])
      ei = ei + 1
    }
    color_idx = color_idx + 1
  }
  elems
}
