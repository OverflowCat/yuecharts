// Corresponds to: echarts/src/chart/lines/LinesSeries.ts
//                  echarts/src/chart/lines/linesLayout.ts
//                  echarts/src/chart/lines/LinesView.ts
//                  echarts/src/chart/lines/install.ts

///|
fn lines_chart_item_coords(item : @option.DataItem) -> Array[Array[Double]]? {
  match item.coords {
    Some(coords) if coords.length() >= 2 => Some(coords)
    _ => None
  }
}

///|
fn lines_chart_geo_named_coords(
  item : @option.DataItem,
  geo : @coord.Geo,
) -> Array[Array[Double]]? {
  match (item.from_name, item.to_name) {
    (Some(from_name), Some(to_name)) =>
      match (geo.region_by_name(from_name), geo.region_by_name(to_name)) {
        (Some(from_region), Some(to_region)) =>
          Some([
            [from_region.center.x, from_region.center.y],
            [to_region.center.x, to_region.center.y],
          ])
        _ => None
      }
    _ => None
  }
}

///|
fn lines_chart_coord_to_point(
  series : @option.SeriesOption,
  coord_pair : Array[Double],
  coord : @coord.Cartesian2D,
  coord_index : Int,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
) -> @graphic.Point? {
  if coord_pair.length() < 2 {
    return None
  }
  match (series.coordinate_system, polar, geo) {
    (Some("geo"), _, Some(g)) =>
      Some(g.data_to_point(coord_pair[0], coord_pair[1]))
    (Some("polar"), Some(p), _) =>
      Some(p.data_to_point(Num(coord_pair[0]), Num(coord_pair[1]), coord_index))
    _ => {
      let x_idx = series.x_axis_index
      let y_idx = series.y_axis_index
      let px = if x_idx < coord.x_scales.length() {
        match coord.x_scales[x_idx] {
          Ordinal(s) => s.band_center(coord_pair[0].to_int())
          Linear(s) => s.data_to_pixel(coord_pair[0])
        }
      } else {
        coord.bbox.x
      }
      let py = coord.num_y(y_idx, coord_pair[1])
      Some(@graphic.Point::new(px, py))
    }
  }
}

///|
fn lines_chart_points(
  series : @option.SeriesOption,
  item : @option.DataItem,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
) -> Array[@graphic.Point] {
  let raw_coords = match (lines_chart_item_coords(item), geo) {
    (Some(coords), _) => Some(coords)
    (None, Some(g)) => lines_chart_geo_named_coords(item, g)
    _ => None
  }
  match raw_coords {
    Some(coords_arr) => {
      let points : Array[@graphic.Point] = []
      let mut i = 0
      while i < coords_arr.length() {
        match
          lines_chart_coord_to_point(
            series,
            coords_arr[i],
            coord,
            i,
            polar~,
            geo~,
          ) {
          Some(point) => points.push(point)
          None => ()
        }
        i += 1
      }
      points
    }
    None => []
  }
}

///|
fn lines_chart_curve_path(
  start : @graphic.Point,
  end : @graphic.Point,
  curveness : Double,
) -> String {
  let cx = (start.x + end.x) / 2.0 - (start.y - end.y) * curveness
  let cy = (start.y + end.y) / 2.0 - (end.x - start.x) * curveness
  "M \{start.x} \{start.y} Q \{cx} \{cy} \{end.x} \{end.y}"
}

///|
pub fn render_lines_chart_series(
  series : @option.SeriesOption,
  series_index : Int,
  coord : @coord.Cartesian2D,
  polar? : @coord.Polar? = None,
  geo? : @coord.Geo? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  let color = series.line_style_color.unwrap_or(
    series.color.unwrap_or(@visual.palette_color(series_index)),
  )
  let width = series.line_style_width.unwrap_or(1.0)
  let opacity = series.line_style_opacity.unwrap_or(0.5)
  let curveness = series.line_style_curveness.unwrap_or(0.0)
  let mut di = 0
  while di < series.data.length() {
    let item = series.data[di]
    let points = lines_chart_points(series, item, coord, polar~, geo~)
    if points.length() >= 2 {
      if series.polyline || points.length() > 2 {
        elems.push(
          @graphic.Element::polyline_custom_opacity(
            points, color, width, "round", "round", opacity,
          ),
        )
      } else if curveness != 0.0 {
        elems.push(
          @graphic.Element::path_stroke_custom(
            lines_chart_curve_path(points[0], points[1], curveness),
            color,
            width,
            "round",
            "round",
            opacity,
          ),
        )
      } else {
        elems.push(
          @graphic.Element::polyline_custom_opacity(
            [points[0], points[1]],
            color,
            width,
            "round",
            "round",
            opacity,
          ),
        )
      }
    }
    di += 1
  }
  elems
}

///|
pub fn render_lines_chart(
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
      Lines =>
        elems.append(render_lines_chart_series(series, si, coord, polar~, geo~))
      _ => ()
    }
    si += 1
  }
  elems
}
