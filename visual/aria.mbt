// Corresponds to: echarts/src/visual/aria.ts
// and echarts/src/component/aria/preprocessor.ts for static option normalization.

///|
fn series_type_name(series_type : @option.SeriesType) -> String {
  match series_type {
    @option.Line => "Line chart"
    @option.Lines => "Lines"
    @option.Bar => "Bar chart"
    @option.PictorialBar => "Pictorial bar"
    @option.Scatter => "Scatter plot"
    @option.EffectScatter => "Ripple scatter plot"
    @option.Pie => "Pie chart"
    @option.Sunburst => "Sunburst"
    @option.Treemap => "Treemap"
    @option.Radar => "Radar chart"
    @option.Candlestick => "Candlestick"
    @option.Heatmap => "Heat map"
    @option.Boxplot => "Boxplot"
    @option.Funnel => "Funnel chart"
    @option.Gauge => "Gauge"
    @option.Map => "Map"
    @option.ThemeRiver => "Theme river"
    @option.Parallel => "Parallel coordinates"
    @option.Tree => "Tree diagram"
    @option.Chord => "Chord chart"
  }
}

///|
fn replace_all(template : String, key : String, value : String) -> String {
  template.replace(old="{" + key + "}", new=value)
}

///|
fn apply_placeholders(
  template : String,
  keys : Array[(String, String)],
) -> String {
  let mut result = template
  let mut i = 0
  while i < keys.length() {
    let (key, value) = keys[i]
    result = replace_all(result, key, value)
    i += 1
  }
  result
}

///|
fn data_value_labels(
  value : @option.DataValue,
  middle_separator : String,
) -> String {
  match value {
    @option.Num(n) => n.to_string()
    @option.Vec(arr) => {
      let labels : Array[String] = []
      let mut i = 0
      while i < arr.length() {
        labels.push(arr[i].to_string())
        i += 1
      }
      labels.join(middle_separator)
    }
    @option.DateValue(date, n) => "\{date}:\{n}"
    @option.Null => "null"
  }
}

///|
fn series_label(
  aria : @option.AriaOption,
  series : @option.SeriesOption,
  series_index : Int,
  series_count : Int,
) -> String {
  let series_name = match series.name {
    Some(name) if name != "" => Some(name)
    _ => None
  }
  let template = if series_count > 1 {
    match series_name {
      Some(_) => aria.series_multiple_with_name
      None => aria.series_multiple_without_name
    }
  } else {
    match series_name {
      Some(_) => aria.series_single_with_name
      None => aria.series_single_without_name
    }
  }
  let header = apply_placeholders(template, [
    ("seriesId", (series_index + 1).to_string()),
    ("seriesName", series_name.unwrap_or("")),
    ("seriesType", series_type_name(series.series_type)),
  ])
  let data_prefix = if series.data.length() > aria.data_max_count {
    apply_placeholders(aria.data_partial_data, [
      ("displayCnt", aria.data_max_count.to_string()),
    ])
  } else {
    aria.data_all_data
  }
  let data_limit = if series.data.length() < aria.data_max_count {
    series.data.length()
  } else {
    aria.data_max_count
  }
  let labels : Array[String] = []
  let mut i = 0
  while i < data_limit {
    let item = series.data[i]
    let template = match item.name {
      Some(_) => aria.data_with_name
      None => aria.data_without_name
    }
    labels.push(
      apply_placeholders(template, [
        ("name", item.name.unwrap_or("")),
        ("value", data_value_labels(item.value, aria.data_separator_middle)),
      ]),
    )
    i += 1
  }
  header +
  data_prefix +
  labels.join(aria.data_separator_middle) +
  aria.data_separator_end
}

///|
pub fn aria_label(opt : @option.ChartOption) -> String? {
  let aria = match opt.aria {
    Some(value) => value
    None => return None
  }
  if !aria.enabled || !aria.label_enabled {
    return None
  }
  match aria.description {
    Some(description) => return Some(description)
    None => ()
  }
  let series_count = opt.series.length()
  if series_count == 0 {
    return None
  }
  let title = match opt.title {
    Some(title) if title.text != "" => Some(title.text)
    _ => None
  }
  let mut result = match title {
    Some(text) => apply_placeholders(aria.general_with_title, [("title", text)])
    None => aria.general_without_title
  }
  let prefix = if series_count > 1 {
    apply_placeholders(aria.series_multiple_prefix, [
      ("seriesCount", series_count.to_string()),
    ])
  } else {
    aria.series_single_prefix
  }
  result = result + prefix
  let display_series_count = if series_count < aria.series_max_count {
    series_count
  } else {
    aria.series_max_count
  }
  let series_labels : Array[String] = []
  let mut i = 0
  while i < display_series_count {
    series_labels.push(series_label(aria, opt.series[i], i, series_count))
    i += 1
  }
  Some(
    result +
    series_labels.join(aria.series_multiple_separator_middle) +
    aria.series_multiple_separator_end,
  )
}
