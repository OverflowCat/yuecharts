// Corresponds to: echarts/src/chart/effectScatter/EffectScatterSeries.ts
//                  echarts/src/chart/effectScatter/EffectScatterView.ts
//                  echarts/src/chart/effectScatter/install.ts
//                  echarts/src/layout/points.ts
//                  echarts/src/chart/helper/EffectSymbol.ts

///|
fn render_effect_ripple(
  elems : Array[@graphic.Element],
  px : Double,
  py : Double,
  color : String,
  symbol_radius : Double,
) -> Unit {
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
    i += 1
  }
}

///|
pub fn render_effect_scatter_series(
  opt : @option.ChartOption,
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let default_color = match series.color {
    Some(c) => c
    None => @visual.palette_color(series_index)
  }
  let mut di = 0
  while di < series.data.length() {
    let item = series.data[di]
    match scatter_point(series, di, item, coord, polar~, geo~) {
      Some(point) => {
        let color = geo_visual_map_color(opt, series_index, item).unwrap_or(
          default_color,
        )
        let symbol_radius = geo_visual_map_symbol_size(
            opt,
            series_index,
            item,
            series.symbol_size,
          ) *
          0.5
        render_effect_ripple(elems, point.x, point.y, color, symbol_radius)
        elems.push(
          @graphic.Element::circle_colored(
            point.x,
            point.y,
            symbol_radius,
            color,
          ),
        )
      }
      None => ()
    }
    di += 1
  }
  elems
}

///|
pub fn render_effect_scatters(
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
      EffectScatter => {
        let series_elems = render_effect_scatter_series(
          opt,
          series,
          si,
          coord,
          polar~,
          geo~,
        )
        let mut ei = 0
        while ei < series_elems.length() {
          elems.push(series_elems[ei])
          ei += 1
        }
      }
      _ => ()
    }
    si += 1
  }
  elems
}
