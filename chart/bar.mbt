// Corresponds to: echarts/src/chart/bar/BarView.ts
//                  echarts/src/layout/barGrid.ts
//                  echarts/src/layout/barPolar.ts

///|
fn bar_r4(v : Double) -> String {
  ((v * 10000.0).round() / 10000.0).to_string()
}

///|
fn bar_sector_path(
  cx : Double,
  cy : Double,
  r0 : Double,
  r1 : Double,
  start_angle_deg : Double,
  end_angle_deg : Double,
) -> String {
  let a0 = -start_angle_deg / 180.0 * @math.PI
  let a1 = -end_angle_deg / 180.0 * @math.PI
  let x0 = cx + r1 * @math.cos(a0)
  let y0 = cy + r1 * @math.sin(a0)
  let x1 = cx + r1 * @math.cos(a1)
  let y1 = cy + r1 * @math.sin(a1)
  let xi0 = cx + r0 * @math.cos(a0)
  let yi0 = cy + r0 * @math.sin(a0)
  let xi1 = cx + r0 * @math.cos(a1)
  let yi1 = cy + r0 * @math.sin(a1)
  let large_arc = if (a1 - a0).abs() > @math.PI { 1 } else { 0 }
  if r0 <= 0.0 {
    "M \{bar_r4(cx)} \{bar_r4(cy)} L \{bar_r4(x0)} \{bar_r4(y0)} A \{bar_r4(r1)} \{bar_r4(r1)} 0 \{large_arc} 1 \{bar_r4(x1)} \{bar_r4(y1)} Z"
  } else {
    "M \{bar_r4(x0)} \{bar_r4(y0)} A \{bar_r4(r1)} \{bar_r4(r1)} 0 \{large_arc} 1 \{bar_r4(x1)} \{bar_r4(y1)} L \{bar_r4(xi1)} \{bar_r4(yi1)} A \{bar_r4(r0)} \{bar_r4(r0)} 0 \{large_arc} 0 \{bar_r4(xi0)} \{bar_r4(yi0)} Z"
  }
}

///|
fn bar_xy_value(item : @option.DataItem, data_index : Int) -> (Double, Double) {
  match item.value {
    Num(n) => (data_index.to_double(), n)
    Vec(arr) =>
      if arr.length() > 1 {
        (arr[0], arr[1])
      } else if arr.length() > 0 {
        (data_index.to_double(), arr[0])
      } else {
        (data_index.to_double(), 0.0)
      }
    DateValue(_, n) => (data_index.to_double(), n)
    Null => (data_index.to_double(), 0.0)
  }
}

///|
fn render_bar_series_polar(
  series : @option.SeriesOption,
  series_index : Int,
  polar : @coord.Polar,
  bar_index : Int,
  total_bars : Int,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let color = match series.color {
    Some(c) => c
    None => @visual.palette_color(series_index)
  }
  let base_axis = polar.get_base_axis()
  let value_axis = polar.get_other_axis(base_axis)
  let n = if total_bars > 0 { total_bars } else { 1 }
  let cat_gap_pct = if 35 - n * 4 > 15 {
    (35 - n * 4).to_double()
  } else {
    15.0
  }
  let mut di = 0
  while di < series.data.length() {
    let item = series.data[di]
    let (data0, data1) = bar_xy_value(item, di)
    let center = if base_axis.dim == "angle" {
      base_axis.data_to_coord(Num(data0), di)
    } else {
      base_axis.data_to_coord(Num(data0), di)
    }
    let band_step = match base_axis.scale {
      Ordinal(s) => s.band_step()
      Linear(_) => if base_axis.dim == "angle" { 30.0 } else { 20.0 }
    }
    let total_span = band_step * (1.0 - cat_gap_pct / 100.0)
    let bar_span = total_span / n.to_double() / 1.3
    let start_coord = center -
      total_span / 2.0 +
      bar_index.to_double() * bar_span * 1.3
    let end_coord = start_coord + bar_span
    if base_axis.dim == "angle" {
      let base_radius = polar.radius_axis.extent_start
      let value_radius = value_axis.data_to_coord(Num(data1), di)
      let r0 = if value_radius >= base_radius {
        base_radius
      } else {
        value_radius
      }
      let r1 = if value_radius >= base_radius {
        value_radius
      } else {
        base_radius
      }
      elems.push(
        @graphic.Element::path_fill_stroke(
          bar_sector_path(polar.cx, polar.cy, r0, r1, start_coord, end_coord),
          color,
          "#ffffff",
          1.0,
          1.0,
        ),
      )
    } else {
      let base_angle = polar.angle_axis.extent_start
      let value_angle = value_axis.data_to_coord(Num(data1), di)
      let a0 = if value_angle >= base_angle { base_angle } else { value_angle }
      let a1 = if value_angle >= base_angle { value_angle } else { base_angle }
      elems.push(
        @graphic.Element::path_fill_stroke(
          bar_sector_path(polar.cx, polar.cy, start_coord, end_coord, a0, a1),
          color,
          "#ffffff",
          1.0,
          1.0,
        ),
      )
    }
    di += 1
  }
  elems
}

///|
pub fn render_bar_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  bar_index : Int,
  total_bars : Int,
  polar? : @coord.Polar? = None,
) -> Array[@graphic.Element] {
  match (series.coordinate_system, polar) {
    (Some("polar"), Some(p)) =>
      return render_bar_series_polar(
        series, series_index, p, bar_index, total_bars,
      )
    _ => ()
  }
  let elems : Array[@graphic.Element] = []
  let x_idx = series.x_axis_index
  let y_idx = series.y_axis_index
  let color = match series.color {
    Some(c) => c
    None => @visual.palette_color(series_index)
  }
  let base_y = coord.bbox.y + coord.bbox.height
  if x_idx >= coord.x_scales.length() {
    return elems
  }
  match coord.x_scales[x_idx] {
    Ordinal(s) => {
      let band_step = s.band_step()
      let n = if total_bars > 0 { total_bars } else { 1 }
      let cat_gap_pct = if 35 - n * 4 > 15 {
        (35 - n * 4).to_double()
      } else {
        15.0
      }
      let total_span = band_step * (1.0 - cat_gap_pct / 100.0)
      let bar_w = total_span / n.to_double() / 1.3
      let nd = series.data.length()
      let mut di = 0
      while di < nd {
        let item = series.data[di]
        di += 1
        let cat_px = if di - 1 < s.categories.length() {
          s.band_center(di - 1)
        } else {
          coord.bbox.x
        }
        let bar_x = cat_px -
          total_span / 2.0 +
          bar_index.to_double() * bar_w * 1.3
        let value = match item.value {
          Num(n) => n
          Vec(arr) => if arr.length() > 1 { arr[1] } else { 0.0 }
          DateValue(_, n) => n
          Null => 0.0
        }
        let top_y = coord.num_y(y_idx, value)
        let bar_h = base_y - top_y
        if bar_h > 0.0 {
          elems.push(
            @graphic.Element::rect_colored(bar_x, top_y, bar_w, bar_h, color),
          )
        }
      }
    }
    Linear(s) => {
      let nd = series.data.length()
      let bar_w = 10.0
      let mut di = 0
      while di < nd {
        let item = series.data[di]
        di += 1
        let (x_val, y_val) = match item.value {
          Num(n) => (di.to_double(), n)
          Vec(arr) =>
            if arr.length() > 1 {
              (arr[0], arr[1])
            } else if arr.length() > 0 {
              (di.to_double(), arr[0])
            } else {
              (di.to_double(), 0.0)
            }
          DateValue(_, n) => (di.to_double(), n)
          Null => (di.to_double(), 0.0)
        }
        let bar_x = s.data_to_pixel(x_val) - bar_w * 0.5
        let top_y = coord.num_y(y_idx, y_val)
        let bar_h = base_y - top_y
        if bar_h > 0.0 {
          elems.push(
            @graphic.Element::rect_colored(bar_x, top_y, bar_w, bar_h, color),
          )
        }
      }
    }
  }
  elems
}

///|
pub fn render_bars(
  opt : @option.ChartOption,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let mut color_idx = 0
  let max_xi = opt.x_axis.length()
  let bar_counts : Array[Int] = []
  let bar_rank_cursor : Array[Int] = []
  let mut xi_init = 0
  while xi_init <= max_xi {
    bar_counts.push(0)
    bar_rank_cursor.push(0)
    xi_init += 1
  }
  let mut count_i = 0
  while count_i < opt.series.length() {
    let s = opt.series[count_i]
    count_i += 1
    match s.series_type {
      Bar => {
        let xi = if s.x_axis_index < max_xi { s.x_axis_index } else { 0 }
        bar_counts[xi] += 1
      }
      _ => ()
    }
  }
  let mut sr = 0
  color_idx = 0
  while sr < opt.series.length() {
    let series = opt.series[sr]
    sr += 1
    match series.series_type {
      Bar => ()
      _ => {
        color_idx += 1
        continue
      }
    }
    let xi = if series.x_axis_index < max_xi { series.x_axis_index } else { 0 }
    let total = bar_counts[xi]
    let rank = bar_rank_cursor[xi]
    bar_rank_cursor[xi] = rank + 1
    let series_elems = render_bar_series(
      series,
      color_idx,
      coord,
      rank,
      total,
      polar~,
    )
    elems.append(series_elems)
    color_idx += 1
  }
  elems
}
