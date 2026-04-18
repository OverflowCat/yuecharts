/// <=> echarts/src/chart/candlestick/CandlestickView.ts
/// <=> echarts/src/chart/candlestick/candlestickLayout.ts
//
// Data format per item: Vec([open, close, low, high])
// Bullish (close >= open): color "#eb5454" (red, Chinese convention: red = up)
// Bearish (close < open):  color "#47b262" (green, Chinese convention: green = down)

///|
/// Default bullish (up/close >= open) candle color — ECharts default.
let candle_color_up : String = "#eb5454"

///|
/// Default bearish (down/close < open) candle color — ECharts default.
let candle_color_down : String = "#47b262"

///|
/// Render a single candlestick series to scene graph elements.
pub fn render_candlestick_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  // Candle body width: 70% of the ordinal band width (or fixed fallback)
  let candle_w = if x_idx < coord.x_scales.length() {
    match coord.x_scales[x_idx] {
      Ordinal(s) => s.band_width() * 0.7
      Linear(_) | BreakLinear(_) => 8.0
    }
  } else {
    8.0
  }
  let any_highlighted = @visual.has_any_highlighted(series.data)
  let nd = series.data.length()
  let mut di = 0
  while di < nd {
    let item = series.data[di]
    di += 1
    match item.value {
      Vec(arr) if arr.length() >= 4 => {
        let open_v = arr[0]
        let close_v = arr[1]
        let low_v = arr[2]
        let high_v = arr[3]
        // X center position
        let cx = if x_idx < coord.x_scales.length() {
          match coord.x_scales[x_idx] {
            Ordinal(s) => s.band_center(di - 1)
            Linear(s) => s.data_to_pixel((di - 1).to_double())
            BreakLinear(s) => s.data_to_pixel((di - 1).to_double())
          }
        } else {
          coord.bbox.x + (di - 1).to_double() * candle_w * 2.0
        }
        // Pixel Y positions (higher value → lower y due to inverted axis)
        let open_y = coord.num_y(y_idx, open_v)
        let close_y = coord.num_y(y_idx, close_v)
        let low_y = coord.num_y(y_idx, low_v)
        let high_y = coord.num_y(y_idx, high_v)
        // Body: from min(open_y, close_y) to max(open_y, close_y)
        let body_top = if open_y < close_y { open_y } else { close_y }
        let body_bot = if open_y > close_y { open_y } else { close_y }
        let body_h = (body_bot - body_top).max(1.0)
        let color = if close_v >= open_v {
          series.candle_color_up.unwrap_or(candle_color_up)
        } else {
          series.candle_color_down.unwrap_or(candle_color_down)
        }
        let is_doji = close_v == open_v
        let border_color = if is_doji {
          // Doji: open == close; use borderColorDoji if set
          if close_v >= open_v {
            match series.candle_border_color_doji {
              Some(c) => c
              None => series.candle_border_color_up.unwrap_or(color)
            }
          } else {
            match series.candle_border_color0_doji {
              Some(c) => c
              None => series.candle_border_color_down.unwrap_or(color)
            }
          }
        } else if close_v >= open_v {
          series.candle_border_color_up.unwrap_or(color)
        } else {
          series.candle_border_color_down.unwrap_or(color)
        }
        let border_width = series.candle_border_width

        // Apply emphasis state if highlighting
        let emphasis_fill = if any_highlighted && item.highlighted == Some(true) {
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

        // Body rect with fill and border
        let body_rect = @graphic.Element::rect_border(
          cx - candle_w * 0.5,
          body_top,
          candle_w,
          body_h,
          color,
          border_color,
          border_width,
        )
        let body_elem = if any_highlighted {
          body_rect
          .with_emphasis_style(emphasis_style)
          .with_blur_style(blur_style)
        } else {
          body_rect
        }
        elems.push(body_elem)

        // Upper wick: from body_top to high_y (high_y < body_top in pixel coords)
        if high_y < body_top {
          let wick_line = @graphic.Element::line_colored(
            cx, high_y, cx, body_top, border_color, 1.0,
          )
          let wick_elem = if any_highlighted {
            wick_line
            .with_emphasis_style(emphasis_style)
            .with_blur_style(blur_style)
          } else {
            wick_line
          }
          elems.push(wick_elem)
        }
        // Lower wick: from body_bot to low_y (low_y > body_bot in pixel coords)
        if low_y > body_bot {
          let wick_line = @graphic.Element::line_colored(
            cx, body_bot, cx, low_y, border_color, 1.0,
          )
          let wick_elem = if any_highlighted {
            wick_line
            .with_emphasis_style(emphasis_style)
            .with_blur_style(blur_style)
          } else {
            wick_line
          }
          elems.push(wick_elem)
        }
      }
      _ => ()
    }
  }
  let _ = series_index // suppress unused warning
  elems
}

///|
/// Render all candlestick series from a ChartOption to scene graph elements.
pub fn render_candlesticks(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []

  for si, _ in opt.series {
    let series = opt.series[si]
    if series.series_type != Candlestick {
      continue
    }
    elems.append(render_candlestick_series(series, si - 1, coord))
  }
  elems
}
