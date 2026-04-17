/// <=> echarts/src/chart/effectScatter/EffectScatterSeries.ts
/// <=> echarts/src/chart/effectScatter/EffectScatterView.ts
/// <=> echarts/src/chart/effectScatter/install.ts
/// <=> echarts/src/layout/points.ts
/// <=> echarts/src/chart/helper/EffectSymbol.ts

///|
fn render_effect_ripple(
  elems : Array[@graphic.Element],
  px : Double,
  py : Double,
  color : String,
  symbol_radius : Double,
  any_highlighted? : Bool = false,
  highlighted? : Bool = false,
) -> Unit {
  let ripple_scales = [2.5, 1.8333333333333333, 1.1666666666666667]
  let ripple_opacities = [0.0, 0.33333333333333337, 0.6666666666666667]
  let emphasis_fill = if highlighted {
    @visual.lift_hex_color(color)
  } else {
    color
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

  for i, sc in ripple_scales {
    let circle = @graphic.Element::circle_colored_opacity(
      px,
      py,
      symbol_radius * sc,
      color,
      ripple_opacities[i],
    )
    elems.push(
      if any_highlighted {
        circle.with_emphasis_style(emphasis_style).with_blur_style(blur_style)
      } else {
        circle
      },
    )
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
  calendar? : @coord.Calendar? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let default_color = scatter_series_color(series, series_index)
  let any_highlighted = @visual.has_any_highlighted(series.data)

  for di, _ in series.data {
    let item = series.data[di]
    match scatter_point(series, di, item, coord, polar~, geo~, calendar~) {
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
        let item_highlighted = item.highlighted == Some(true)
        render_effect_ripple(
          elems,
          point.x,
          point.y,
          color,
          symbol_radius,
          any_highlighted~,
          highlighted=item_highlighted,
        )
        let emphasis_fill = if item_highlighted {
          @visual.lift_hex_color(color)
        } else {
          color
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
        let core = @graphic.Element::circle_colored(
          point.x,
          point.y,
          symbol_radius,
          color,
        )
        elems.push(
          if any_highlighted {
            core.with_emphasis_style(emphasis_style).with_blur_style(blur_style)
          } else {
            core
          },
        )
      }
      None => ()
    }
  }
  elems
}

///|
pub fn render_effect_scatters(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
  calendar? : @coord.Calendar? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  for si, series in opt.series {
    if series.series_type != EffectScatter {
      continue
    }
    let r = render_effect_scatter_series(
      opt,
      series,
      si,
      coord,
      polar~,
      geo~,
      calendar~,
    )
    elems.append(r)
  }
  elems
}
