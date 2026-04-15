/// <=> echarts/src/chart/parallel/ParallelView.ts
/// <=> echarts/src/chart/parallel/ParallelSeries.ts
/// <=> echarts/src/chart/parallel/parallelVisual.ts

///|
pub fn render_parallel_series(
  series : @option.SeriesOption,
  series_index : Int,
  parallel : @coord.Parallel,
) -> Array[@graphic.Element] {
  let line_elems : Array[@graphic.Element] = []
  let color = series.line_style_color.unwrap_or(
    series.color.unwrap_or(@visual.palette_color(series_index)),
  )
  let width = series.line_style_width.unwrap_or(1.0)
  let opacity = series.line_style_opacity.unwrap_or(0.45)
  let mut i = 0
  for i, _ in series.data {
    let item = series.data[i]
    let points = parallel_series_line_points(item, parallel)
    if points.length() < 2 {
      continue
    }
    line_elems.push(
      @graphic.Element::polyline_custom_opacity(
        points, color, width, "round", "round", opacity,
      ),
    )
  }
  if line_elems.length() == 0 {
    []
  } else {
    [@graphic.Element::group_clipped(line_elems, parallel.bbox)]
  }
}

///|
pub fn render_parallels(
  opt : @option.ChartOption,
  parallel? : @coord.Parallel? = None,
) -> Array[@graphic.Element] {
  let elems : Array[@graphic.Element] = []
  guard parallel is Some(coord) else { elems }
  let mut si = 0
  let mut color_index = 0
  for si, _ in opt.series {
    let series = opt.series[si]
    if series.series_type == @option.SeriesType::Parallel {
      elems.append(render_parallel_series(series, color_index, coord))
    }
    color_index += 1
  }
  elems
}

///|
fn parallel_series_line_points(
  item : @option.DataItem,
  parallel : @coord.Parallel,
) -> Array[@graphic.Point] {
  let points : Array[@graphic.Point] = []
  let mut i = 0
  for i, _ in parallel.dimensions {
    let dim = parallel.dimensions[i]
    match parallel.data_to_point(item.value, dim) {
      Some(point) => points.push(point)
      None => ()
    }
  }
  points
}
