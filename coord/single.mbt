// Corresponds to: echarts/src/coord/single/Single.ts
//                  echarts/src/coord/single/SingleAxis.ts
//                  echarts/src/coord/single/AxisModel.ts
//                  echarts/src/coord/single/singleCreator.ts
//                  echarts/src/coord/single/singleAxisHelper.ts
//                  echarts/src/coord/single/prepareCustom.ts

///|
/// A computed Single 1-D coordinate system bounding box.
/// Corresponds to: Single._rect in Single.ts
pub(all) struct SingleBBox {
  x : Double
  y : Double
  width : Double
  height : Double
}

///|
/// The Single 1-D coordinate system runtime model.
/// Corresponds to: echarts/src/coord/single/Single.ts
pub(all) struct Single {
  bbox : SingleBBox
  orient : String // "horizontal" | "vertical"
  axis_type : @option.AxisType
  min_val : Double
  max_val : Double
  inverse : Bool
  position : String // "top"|"bottom"|"left"|"right"
  // sorted unique date strings for category/time mode
  labels : Array[String]
  time_labels : Array[String]
}

///|
pub(all) struct SingleLayout {
  x : Double
  y : Double
  rotation : Double
  label_rotate : Double
  label_direction : Int
  tick_direction : Int
  name_direction : Int
  z2 : Int
}

///|
pub(all) struct SinglePrepareCoordSysInfo {
  type_name : String
  x : Double
  y : Double
  width : Double
  height : Double
}

///|
pub(all) struct SinglePreparedCustom {
  coord_sys : SinglePrepareCoordSysInfo
}

///|
/// Parse a date string "YYYY/MM/DD" or "YYYY-MM-DD" to a Julian-like day count.
/// Corresponds to: echarts/src/util/number.ts parseDate()
fn parse_date_to_days(s : String) -> Double {
  // Normalize: replace "/" with "-".
  let normalized = s.replace(old="/", new="-")
  // Fast path for canonical date strings like YYYY-MM-DD.
  if normalized.length() < 10 {
    let r = try? @string.parse_double(s)
    match r {
      Ok(v) => return v
      Err(_) => return 0.0
    }
  }
  let y_str = normalized[:4].to_string()
  let m_str = normalized[5:7].to_string()
  let d_str = normalized[8:10].to_string()
  let year_r = try? @string.parse_int(y_str, base=10)
  let year = match year_r {
    Ok(v) => v
    Err(_) => 1970
  }
  let month_r = try? @string.parse_int(m_str, base=10)
  let month = match month_r {
    Ok(v) => v
    Err(_) => 1
  }
  let day_r = try? @string.parse_int(d_str, base=10)
  let day = match day_r {
    Ok(v) => v
    Err(_) => 1
  }
  // Gregorian day count from 1970-01-01
  // Use standard algorithm: count days for each year + month + day
  let days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  let mut total = 0
  // Days for complete years from 1970 to year-1
  let mut y = 1970
  while y < year {
    if is_leap_year(y) {
      total += 366
    } else {
      total += 365
    }
    y += 1
  }
  // But if year < 1970 we'd go negative, handle that:
  // (re-compute for year < 1970 by subtracting)
  if year < 1970 {
    total = 0
    let mut yy = year
    while yy < 1970 {
      if is_leap_year(yy) {
        total -= 366
      } else {
        total -= 365
      }
      yy += 1
    }
  }
  // Days for complete months in `year` up to month-1
  let mut m = 1
  while m < month {
    let dim = days_in_month[m - 1]
    let extra = if m == 2 && is_leap_year(year) { 1 } else { 0 }
    total += dim + extra
    m += 1
  }
  // Add day-1 (0-indexed within month)
  total += day - 1
  total.to_double()
}

///|
fn is_leap_year(y : Int) -> Bool {
  (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
}

///|
fn resolve_size_spec(
  spec : @option.SizeSpec?,
  total : Double,
  default_val : Double,
) -> Double {
  match spec {
    Some(Px(px)) => px
    Some(Pct(pct)) => total * pct / 100.0
    None => default_val
  }
}

///|
fn single_series_items(
  series : @option.SeriesOption,
) -> Array[@option.DataItem] {
  @data.SeriesData::from_series(series).raw_items()
}

///|
/// Build the Single coordinate system from chart options.
/// Corresponds to: echarts/src/coord/single/singleCreator.ts + Single.resize()
pub fn Single::build(opt : @option.ChartOption) -> Single? {
  if opt.single_axis.length() == 0 {
    return None
  }
  let ax = opt.single_axis[0]
  let w = opt.width
  let h = opt.height
  // Compute insets
  let left = resolve_size_spec(ax.left, w, w * 0.05)
  let top = resolve_size_spec(ax.top, h, h * 0.05)
  let right = resolve_size_spec(ax.right, w, w * 0.05)
  let bottom_inset = resolve_size_spec(ax.bottom, h, h * 0.05)
  let width = match ax.width {
    Some(spec) => resolve_size_spec(Some(spec), w, w - left - right)
    None => w - left - right
  }
  let height = match ax.height {
    Some(spec) => resolve_size_spec(Some(spec), h, h - top - bottom_inset)
    None => h - top - bottom_inset
  }
  let bbox : SingleBBox = { x: left, y: top, width, height }
  // Gather all values from themeRiver series to determine scale extent
  let mut min_val = 0.0
  let mut max_val = 0.0
  let mut first_val = true
  let collected_labels : Array[String] = []
  let collected_time_labels : Array[String] = []
  for i, _ in opt.series {
    let s = opt.series[i]
    if s.series_type == @option.SeriesType::ThemeRiver {
      let items = single_series_items(s)
      let mut j = 0
      for j, _ in items {
        let item = items[j]
        match item.value {
          @option.DataValue::DateValue(date_str, _) => {
            let v = if ax.axis_type == @option.AxisType::Time ||
              ax.axis_type == @option.AxisType::Value {
              if ax.axis_type == @option.AxisType::Time &&
                ax.data.length() == 0 &&
                !array_contains_string(collected_time_labels, date_str) {
                collected_time_labels.push(date_str)
              }
              parse_date_to_days(date_str)
            } else {
              // category: add to labels
              if ax.data.length() == 0 &&
                !array_contains_string(collected_labels, date_str) {
                collected_labels.push(date_str)
              }
              0.0
            }
            if ax.axis_type != @option.AxisType::Category {
              if first_val {
                min_val = v
                max_val = v
                first_val = false
              } else {
                if v < min_val {
                  min_val = v
                }
                if v > max_val {
                  max_val = v
                }
              }
            }
          }
          _ => ()
        }
      }
    }
  }
  // Apply explicit min/max overrides from option
  match ax.min {
    Some(v) => min_val = v
    None => ()
  }
  match ax.max {
    Some(v) => max_val = v
    None => ()
  }
  let labels : Array[String] = []
  let time_labels : Array[String] = []
  // For category axis, labels come from axis.data or collected series values.
  if ax.axis_type == @option.AxisType::Category {
    if ax.data.length() > 0 {
      for value in ax.data {
        labels.push(value)
      }
    } else {
      for value in collected_labels {
        labels.push(value)
      }
      sort_strings_inplace(labels)
    }
    if labels.length() > 0 {
      min_val = 0.0
      max_val = (labels.length() - 1).to_double()
    }
  } else if ax.axis_type == @option.AxisType::Time {
    if ax.data.length() > 0 {
      for value in ax.data {
        time_labels.push(value)
      }
    } else {
      for value in collected_time_labels {
        time_labels.push(value)
      }
    }
    sort_date_strings(time_labels)
    if time_labels.length() > 0 {
      let first_tick = parse_date_to_days(time_labels[0])
      let last_tick = parse_date_to_days(time_labels[time_labels.length() - 1])
      if first_val {
        min_val = first_tick
        max_val = last_tick
      } else {
        if first_tick < min_val {
          min_val = first_tick
        }
        if last_tick > max_val {
          max_val = last_tick
        }
      }
    }
  }
  if min_val > max_val {
    min_val = 0.0
    max_val = 1.0
  }
  Some({
    bbox,
    orient: ax.orient,
    axis_type: ax.axis_type,
    min_val,
    max_val,
    inverse: ax.inverse,
    position: ax.position,
    labels,
    time_labels,
  })
}

///|
fn array_contains_string(arr : Array[String], value : String) -> Bool {
  arr.contains(value)
}

///|
/// Simple in-place insertion sort for string arrays.
fn sort_strings_inplace(arr : Array[String]) -> Unit {
  let n = arr.length()
  let mut i = 1
  while i < n {
    let key = arr[i]
    let mut j = i - 1
    while j >= 0 && arr[j] > key {
      arr[j + 1] = arr[j]
      j -= 1
    }
    arr[j + 1] = key
    i += 1
  }
}

///|
/// Public API for sorting date strings used by the themeRiver chart.
pub fn sort_date_strings(arr : Array[String]) -> Unit {
  let n = arr.length()
  let mut i = 1
  while i < n {
    let key = arr[i]
    let key_num = parse_date_to_days(key)
    let mut j = i - 1
    while j >= 0 && parse_date_to_days(arr[j]) > key_num {
      arr[j + 1] = arr[j]
      j -= 1
    }
    arr[j + 1] = key
    i += 1
  }
}

///|
/// Convert a data value string to a numeric value for the single axis.
/// For time/value axis: parse to day count. For category: ordinal index.
fn Single::val_to_num(self : Single, val_str : String) -> Double {
  match self.axis_type {
    @option.AxisType::Category => {
      for i, x in self.labels {
        if x == val_str {
          return i.to_double()
        }
      }
      0.0
    }
    _ => parse_date_to_days(val_str)
  }
}

///|
/// Public numeric conversion used by strict ports that need raw axis-value ordering.
pub fn Single::value_num(self : Single, val_str : String) -> Double {
  self.val_to_num(val_str)
}

///|
/// Map a data value to a pixel coordinate on the single axis.
/// Corresponds to: Single.dataToPoint() in Single.ts
pub fn Single::data_to_pixel(self : Single, val_str : String) -> Double {
  let v = self.val_to_num(val_str)
  let range = self.max_val - self.min_val
  if range == 0.0 {
    return if self.orient == "horizontal" {
      self.bbox.x + self.bbox.width / 2.0
    } else {
      self.bbox.y + self.bbox.height / 2.0
    }
  }
  let t = (v - self.min_val) / range
  let t_oriented = if self.inverse { 1.0 - t } else { t }
  if self.orient == "horizontal" {
    self.bbox.x + t_oriented * self.bbox.width
  } else {
    // vertical: top = min, bottom = max in display coords (y increases down)
    // but the axis uses the inverse convention for y
    self.bbox.y + (1.0 - t_oriented) * self.bbox.height
  }
}

///|
pub fn Single::data_to_point(self : Single, val_str : String) -> @graphic.Point {
  if self.orient == "horizontal" {
    @graphic.Point::new(
      self.data_to_pixel(val_str),
      self.bbox.y + self.bbox.height / 2.0,
    )
  } else {
    @graphic.Point::new(
      self.bbox.x + self.bbox.width / 2.0,
      self.data_to_pixel(val_str),
    )
  }
}

///|
fn Single::pixel_to_value_num(self : Single, pixel : Double) -> Double {
  let range = self.max_val - self.min_val
  let axis_size = if self.orient == "horizontal" {
    self.bbox.width
  } else {
    self.bbox.height
  }
  if range == 0.0 || axis_size == 0.0 {
    return self.min_val
  }
  let t_oriented = if self.orient == "horizontal" {
    (pixel - self.bbox.x) / axis_size
  } else {
    1.0 - (pixel - self.bbox.y) / axis_size
  }
  let t = if self.inverse { 1.0 - t_oriented } else { t_oriented }
  self.min_val + range * t
}

///|
pub fn Single::point_to_data(
  self : Single,
  point : @graphic.Point,
) -> Array[Double] {
  if self.orient == "horizontal" {
    [self.pixel_to_value_num(point.x)]
  } else {
    [self.pixel_to_value_num(point.y)]
  }
}

///|
pub fn Single::contain_point(self : Single, point : @graphic.Point) -> Bool {
  if self.orient == "horizontal" {
    point.x >= self.bbox.x &&
    point.x <= self.bbox.x + self.bbox.width &&
    point.y >= self.bbox.y &&
    point.y <= self.bbox.y + self.bbox.height
  } else {
    point.y >= self.bbox.y &&
    point.y <= self.bbox.y + self.bbox.height &&
    point.x >= self.bbox.y &&
    point.x <= self.bbox.y + self.bbox.height
  }
}

///|
pub fn Single::layout(
  self : Single,
  axis_option : @option.SingleAxisOption,
) -> SingleLayout {
  let bbox = self.bbox
  let horizontal_axis_y = if self.position == "top" {
    bbox.y
  } else {
    bbox.y + bbox.height
  }
  let vertical_axis_x = if self.position == "right" {
    bbox.x + bbox.width
  } else {
    bbox.x
  }
  let (x, y) = if self.orient == "vertical" {
    (vertical_axis_x, bbox.y + bbox.height)
  } else {
    (bbox.x, horizontal_axis_y)
  }
  let rotation = if self.orient == "vertical" { @math.PI / 2.0 } else { 0.0 }
  let direction = match self.position {
    "top" | "left" => -1
    _ => 1
  }
  let tick_direction = if axis_option.axis_tick.inside {
    -direction
  } else {
    direction
  }
  let label_direction = if axis_option.axis_label.inside {
    -direction
  } else {
    direction
  }
  let label_rotate = if self.position == "top" {
    -axis_option.axis_label.rotate
  } else {
    axis_option.axis_label.rotate
  }
  {
    x,
    y,
    rotation,
    label_rotate,
    label_direction,
    tick_direction,
    name_direction: direction,
    z2: 1,
  }
}

///|
pub fn Single::prepare_custom(self : Single) -> SinglePreparedCustom {
  {
    coord_sys: {
      type_name: "singleAxis",
      x: self.bbox.x,
      y: self.bbox.y,
      width: self.bbox.width,
      height: self.bbox.height,
    },
  }
}

///|
/// Get all unique sorted data values as day-numbers from themeRiver series.
pub fn Single::collect_time_values(
  self : Single,
  opt : @option.ChartOption,
) -> Array[Double] {
  let vals : Array[Double] = []
  for i, _ in opt.series {
    let s = opt.series[i]
    if s.series_type == @option.SeriesType::ThemeRiver {
      let items = single_series_items(s)
      let mut j = 0
      for j, _ in items {
        match items[j].value {
          @option.DataValue::DateValue(d, _) => {
            let v = self.val_to_num(d)
            let mut found = false
            let mut k = 0
            for k, _ in vals {
              if vals[k] == v {
                found = true
                break
              }
            }
            if !found {
              vals.push(v)
            }
          }
          _ => ()
        }
      }
    }
  }
  // Sort ascending
  sort_doubles_inplace(vals)
  vals
}

///|
fn sort_doubles_inplace(arr : Array[Double]) -> Unit {
  let n = arr.length()
  let mut i = 1
  while i < n {
    let key = arr[i]
    let mut j = i - 1
    while j >= 0 && arr[j] > key {
      arr[j + 1] = arr[j]
      j -= 1
    }
    arr[j + 1] = key
    i += 1
  }
}

///|
pub(all) struct SingleTick {
  value : Double
  label : String
}

///|
fn format_time_tick_label(raw : String) -> String {
  if raw.length() >= 2 {
    let day = raw[raw.length() - 2:].to_string()
    let parsed = try? @string.parse_int(day, base=10)
    match parsed {
      Ok(v) => v.to_string()
      Err(_) => raw
    }
  } else {
    raw
  }
}

///|
/// Compute ticks for rendering the single axis.
pub fn Single::axis_ticks(self : Single, count : Int) -> Array[SingleTick] {
  if self.labels.length() > 0 {
    // Category/explicit label mode: one tick per label
    let result : Array[SingleTick] = []
    for i, _ in self.labels {
      result.push({ value: i.to_double(), label: self.labels[i] })
    }
    return result
  }
  if self.axis_type == @option.AxisType::Time && self.time_labels.length() > 0 {
    let result : Array[SingleTick] = []
    for i, _ in self.time_labels {
      let raw = self.time_labels[i]
      result.push({
        value: self.val_to_num(raw),
        label: format_time_tick_label(raw),
      })
    }
    return result
  }
  // Numeric/time mode: generate evenly spaced ticks
  let range = self.max_val - self.min_val
  if range == 0.0 {
    return [{ value: self.min_val, label: self.min_val.to_string() }]
  }
  let n = if count <= 0 { 5 } else { count }
  let result : Array[SingleTick] = []
  let mut i = 0
  while i < n {
    let v = self.min_val + range * i.to_double() / (n - 1).to_double()
    result.push({ value: v, label: v.to_string() })
    i += 1
  }
  result
}
