// Corresponds to: echarts/src/coord/calendar/Calendar.ts
// and echarts/src/coord/calendar/CalendarModel.ts
// and echarts/src/coord/calendar/prepareCustom.ts

///|
pub struct CalendarParsedDateInfo {
  y : String
  m : String
  d : String
  day : Int
  time : Int
  formated_date : String
}

///|
pub struct CalendarParsedDateRangeInfo {
  range : Array[String]
  start : CalendarParsedDateInfo
  end : CalendarParsedDateInfo
  all_day : Int
  weeks : Int
  nth_week : Int
  fweek : Int
  lweek : Int
}

///|
pub struct CalendarCellRect {
  center : @graphic.Point
  tl : @graphic.Point
  tr : @graphic.Point
  br : @graphic.Point
  bl : @graphic.Point
}

///|
pub struct CalendarPrepareRangeInfo {
  start : CalendarParsedDateInfo
  end : CalendarParsedDateInfo
  weeks : Int
  day_count : Int
}

///|
pub struct CalendarPrepareCoordSysInfo {
  type_name : String
  x : Double
  y : Double
  width : Double
  height : Double
  cell_width : Double
  cell_height : Double
  range_info : CalendarPrepareRangeInfo
}

///|
pub struct CalendarPreparedCustom {
  coord_sys : CalendarPrepareCoordSysInfo
}

///|
pub struct Calendar {
  rect : @graphic.BBox
  sw : Double
  sh : Double
  orient : String
  first_day_of_week : Int
  range_info : CalendarParsedDateRangeInfo
  line_width : Double
}

///|
pub fn Calendar::get_range_info(self : Calendar) -> CalendarParsedDateRangeInfo {
  self.range_info
}

///|
pub fn Calendar::get_rect(self : Calendar) -> @graphic.BBox {
  self.rect
}

///|
pub fn Calendar::get_cell_width(self : Calendar) -> Double {
  self.sw
}

///|
pub fn Calendar::get_cell_height(self : Calendar) -> Double {
  self.sh
}

///|
pub fn Calendar::get_orient(self : Calendar) -> String {
  self.orient
}

///|
pub fn Calendar::get_first_day_of_week(self : Calendar) -> Int {
  self.first_day_of_week
}

///|
pub fn Calendar::prepare_custom(self : Calendar) -> CalendarPreparedCustom {
  let range_info = self.range_info
  {
    coord_sys: {
      type_name: "calendar",
      x: self.rect.x,
      y: self.rect.y,
      width: self.rect.width,
      height: self.rect.height,
      cell_width: self.sw,
      cell_height: self.sh,
      range_info: {
        start: range_info.start,
        end: range_info.end,
        weeks: range_info.weeks,
        day_count: range_info.all_day,
      },
    },
  }
}

///|
pub fn Calendar::build(opt : @option.ChartOption) -> Calendar? {
  if opt.calendar.length() == 0 {
    return None
  }
  let model = opt.calendar[0]
  let first_day_of_week = model.day_label.first_day
  let orient = model.orient
  let line_width = model.item_style.border_width
  let range = init_range_option(first_day_of_week, model.range)
  let range_info = get_range_info(first_day_of_week, range)
  let weeks = if range_info.weeks > 0 { range_info.weeks } else { 1 }
  let cell_numbers = if orient == "horizontal" {
    (weeks, 7)
  } else {
    (7, weeks)
  }
  let (layout_width, layout_height) = compute_calendar_size(
    model, opt, cell_numbers,
  )
  let x = compute_calendar_x(model, opt.width, layout_width)
  let y = compute_calendar_y(model, opt.height, layout_height)
  let rect = @graphic.BBox::new(x, y, layout_width, layout_height)
  let sw = layout_width / cell_numbers.0.to_double()
  let sh = layout_height / cell_numbers.1.to_double()
  Some({ rect, sw, sh, orient, first_day_of_week, range_info, line_width })
}

///|
fn compute_calendar_size(
  model : @option.CalendarOption,
  opt : @option.ChartOption,
  cell_numbers : (Int, Int),
) -> (Double, Double) {
  let width = match model.width {
    Some(spec) => resolve_size(spec, opt.width)
    None =>
      match model.cell_size[0] {
        @option.Px(px) => px * cell_numbers.0.to_double()
        @option.Auto => {
          let left = resolve_size_opt(model.left, opt.width, 80.0)
          let right = resolve_size_opt(model.right, opt.width, 0.0)
          opt.width - left - right
        }
      }
  }
  let height = match model.height {
    Some(spec) => resolve_size(spec, opt.height)
    None =>
      match model.cell_size[1] {
        @option.Px(px) => px * cell_numbers.1.to_double()
        @option.Auto => {
          let top = resolve_size_opt(model.top, opt.height, 60.0)
          let bottom = resolve_size_opt(model.bottom, opt.height, 0.0)
          opt.height - top - bottom
        }
      }
  }
  (width, height)
}

///|
fn compute_calendar_x(
  model : @option.CalendarOption,
  total_width : Double,
  layout_width : Double,
) -> Double {
  match model.left {
    Some(spec) => resolve_size(spec, total_width)
    None =>
      match model.right {
        Some(spec) =>
          total_width - resolve_size(spec, total_width) - layout_width
        None => 80.0
      }
  }
}

///|
fn compute_calendar_y(
  model : @option.CalendarOption,
  total_height : Double,
  layout_height : Double,
) -> Double {
  match model.top {
    Some(spec) => resolve_size(spec, total_height)
    None =>
      match model.bottom {
        Some(spec) =>
          total_height - resolve_size(spec, total_height) - layout_height
        None => 60.0
      }
  }
}

///|
fn resolve_size(spec : @option.SizeSpec, total : Double) -> Double {
  match spec {
    @option.Px(px) => px
    @option.Pct(pct) => total * pct / 100.0
  }
}

///|
fn resolve_size_opt(
  spec : @option.SizeSpec?,
  total : Double,
  fallback : Double,
) -> Double {
  match spec {
    Some(value) => resolve_size(value, total)
    None => fallback
  }
}

///|
pub fn Calendar::get_date_info(
  self : Calendar,
  date : String,
) -> CalendarParsedDateInfo {
  get_date_info(self.first_day_of_week, date)
}

///|
pub fn Calendar::get_next_n_day(
  self : Calendar,
  date : String,
  n : Int,
) -> CalendarParsedDateInfo {
  get_next_n_day(self.first_day_of_week, date, n)
}

///|
pub fn Calendar::data_to_point(
  self : Calendar,
  date : String,
  clamp? : Bool = true,
) -> @graphic.Point {
  let day_info = self.get_date_info(date)
  let range = self.range_info
  if clamp &&
    !(day_info.time >= range.start.time && day_info.time <= range.end.time) {
    return @graphic.Point::new(0.0 / 0.0, 0.0 / 0.0)
  }
  let week = day_info.day
  let nth_week = get_range_info(self.first_day_of_week, [
      range.start.formated_date,
      day_info.formated_date,
    ]).nth_week
  if self.orient == "vertical" {
    @graphic.Point::new(
      self.rect.x + week.to_double() * self.sw + self.sw / 2.0,
      self.rect.y + nth_week.to_double() * self.sh + self.sh / 2.0,
    )
  } else {
    @graphic.Point::new(
      self.rect.x + nth_week.to_double() * self.sw + self.sw / 2.0,
      self.rect.y + week.to_double() * self.sh + self.sh / 2.0,
    )
  }
}

///|
pub fn Calendar::data_to_calendar_layout(
  self : Calendar,
  date : String,
  clamp? : Bool = true,
) -> CalendarCellRect {
  let point = self.data_to_point(date, clamp~)
  {
    center: point,
    tl: @graphic.Point::new(point.x - self.sw / 2.0, point.y - self.sh / 2.0),
    tr: @graphic.Point::new(point.x + self.sw / 2.0, point.y - self.sh / 2.0),
    br: @graphic.Point::new(point.x + self.sw / 2.0, point.y + self.sh / 2.0),
    bl: @graphic.Point::new(point.x - self.sw / 2.0, point.y + self.sh / 2.0),
  }
}

///|
pub fn Calendar::point_to_date(
  self : Calendar,
  point : @graphic.Point,
) -> CalendarParsedDateInfo? {
  let nth_x = ((point.x - self.rect.x) / self.sw).floor().to_int() + 1
  let nth_y = ((point.y - self.rect.y) / self.sh).floor().to_int() + 1
  let range = self.range_info.range
  if self.orient == "vertical" {
    get_date_by_weeks_and_day(self.first_day_of_week, nth_y, nth_x - 1, range)
  } else {
    get_date_by_weeks_and_day(self.first_day_of_week, nth_x, nth_y - 1, range)
  }
}

///|
pub fn Calendar::point_to_data(
  self : Calendar,
  point : @graphic.Point,
) -> String? {
  match self.point_to_date(point) {
    Some(date) => Some(date.formated_date)
    None => None
  }
}

///|
pub fn Calendar::data_to_layout(
  self : Calendar,
  date : String,
  clamp? : Bool = true,
) -> @graphic.BBox {
  let point = self.data_to_point(date, clamp~)
  @graphic.BBox::new(
    point.x - self.sw / 2.0,
    point.y - self.sh / 2.0,
    self.sw,
    self.sh,
  )
}

///|
fn init_range_option(
  first_day_of_week : Int,
  range : Array[String],
) -> Array[String] {
  let mut normalized_range = range
  if range.length() == 1 {
    let range_str = normalize_date_separators(range[0])
    if is_year_range(range_str) {
      normalized_range = [range_str + "-01-01", range_str + "-12-31"]
    } else if is_month_range(range_str) {
      let start = get_date_info(first_day_of_week, range_str + "-01")
      let (ny, nm) = next_month(to_int_or(start.y, 1970), to_int_or(start.m, 1))
      let first_day = format_date(ny, nm, 1)
      let end = get_next_n_day(first_day_of_week, first_day, -1)
      normalized_range = [start.formated_date, end.formated_date]
    } else if is_day_range(range_str) {
      normalized_range = [range_str, range_str]
    }
  }
  if normalized_range.length() >= 2 {
    let tmp = get_range_info(first_day_of_week, normalized_range)
    if tmp.start.time > tmp.end.time {
      [normalized_range[1], normalized_range[0]]
    } else {
      normalized_range
    }
  } else {
    normalized_range
  }
}

///|
fn get_range_info(
  first_day_of_week : Int,
  range : Array[String],
) -> CalendarParsedDateRangeInfo {
  let parsed_start = get_date_info(first_day_of_week, range[0])
  let parsed_end = get_date_info(first_day_of_week, range[1])
  let reversed = parsed_start.time > parsed_end.time
  let start = if reversed { parsed_end } else { parsed_start }
  let end = if reversed { parsed_start } else { parsed_end }
  let all_day = end.time - start.time + 1
  let weeks = (all_day + start.day + 6) / 7
  let nth_week = if reversed { -weeks + 1 } else { weeks - 1 }
  {
    range: [start.formated_date, end.formated_date],
    start: if reversed {
      parsed_start
    } else {
      parsed_start
    },
    end: if reversed {
      parsed_end
    } else {
      parsed_end
    },
    all_day,
    weeks,
    nth_week,
    fweek: start.day,
    lweek: end.day,
  }
}

///|
fn get_date_by_weeks_and_day(
  first_day_of_week : Int,
  nth_week : Int,
  day : Int,
  range : Array[String],
) -> CalendarParsedDateInfo? {
  let range_info = get_range_info(first_day_of_week, range)
  if nth_week > range_info.weeks ||
    (nth_week == 0 && day < range_info.fweek) ||
    (nth_week == range_info.weeks && day > range_info.lweek) {
    return None
  }
  let nth_day = (nth_week - 1) * 7 - range_info.fweek + day
  let serial = range_info.start.time + nth_day
  Some(get_date_info(first_day_of_week, serial_to_date_string(serial)))
}

///|
fn get_next_n_day(
  first_day_of_week : Int,
  date : String,
  n : Int,
) -> CalendarParsedDateInfo {
  let info = get_date_info(first_day_of_week, date)
  let serial = info.time + n
  get_date_info(first_day_of_week, serial_to_date_string(serial))
}

///|
fn get_date_info(
  first_day_of_week : Int,
  date : String,
) -> CalendarParsedDateInfo {
  let (y, m, d) = parse_date_string(date)
  let serial = days_from_civil(y, m, d)
  let weekday = positive_mod(serial + 4, 7)
  let day = positive_mod(weekday + 7 - first_day_of_week, 7)
  let m_str = two_digit(m)
  let d_str = two_digit(d)
  {
    y: y.to_string(),
    m: m_str,
    d: d_str,
    day,
    time: serial,
    formated_date: "\{y}-\{m_str}-\{d_str}",
  }
}

///|
fn parse_date_string(date : String) -> (Int, Int, Int) {
  let parts = split_date_parts(normalize_date_separators(date))
  if parts.length() >= 3 {
    (to_int_or(parts[0], 1970), to_int_or(parts[1], 1), to_int_or(parts[2], 1))
  } else if parts.length() == 2 {
    (to_int_or(parts[0], 1970), to_int_or(parts[1], 1), 1)
  } else if parts.length() == 1 {
    (to_int_or(parts[0], 1970), 1, 1)
  } else {
    (1970, 1, 1)
  }
}

///|
fn normalize_date_separators(date : String) -> String {
  date.replace(old="/", new="-")
}

///|
fn is_year_range(value : String) -> Bool {
  value.length() == 4 && is_all_digits(value)
}

///|
fn is_month_range(value : String) -> Bool {
  let parts = split_date_parts(value)
  parts.length() == 2 && is_all_digits(parts[0]) && is_all_digits(parts[1])
}

///|
fn is_day_range(value : String) -> Bool {
  let parts = split_date_parts(value)
  parts.length() == 3 &&
  is_all_digits(parts[0]) &&
  is_all_digits(parts[1]) &&
  is_all_digits(parts[2])
}

///|
fn is_all_digits(value : String) -> Bool {
  if value == "" {
    return false
  }
  let mut i = 0
  while i < value.length() {
    let c = value[i]
    if c < '0' || c > '9' {
      return false
    }
    i += 1
  }
  true
}

///|
fn to_int_or(value : String, fallback : Int) -> Int {
  let r = try? @strconv.parse_int(value)
  match r {
    Ok(v) => v
    Err(_) => fallback
  }
}

///|
fn split_date_parts(value : String) -> Array[String] {
  let parts : Array[String] = []
  let mut start = 0
  let mut i = 0
  while i < value.length() {
    if value[i] == '-' {
      parts.push(value[start:i].to_string())
      start = i + 1
    }
    i += 1
  }
  parts.push(value[start:value.length()].to_string())
  parts
}

///|
fn two_digit(value : Int) -> String {
  if value < 10 {
    "0\{value}"
  } else {
    value.to_string()
  }
}

///|
fn format_date(y : Int, m : Int, d : Int) -> String {
  "\{y}-\{two_digit(m)}-\{two_digit(d)}"
}

///|
fn serial_to_date_string(serial : Int) -> String {
  let (y, m, d) = civil_from_days(serial)
  format_date(y, m, d)
}

///|
fn next_month(y : Int, m : Int) -> (Int, Int) {
  if m == 12 {
    (y + 1, 1)
  } else {
    (y, m + 1)
  }
}

///|
fn positive_mod(value : Int, m : Int) -> Int {
  let r = value % m
  if r < 0 {
    r + m
  } else {
    r
  }
}

///|
fn days_from_civil(y0 : Int, m0 : Int, d : Int) -> Int {
  let y = if m0 <= 2 { y0 - 1 } else { y0 }
  let era = if y >= 0 { y / 400 } else { (y - 399) / 400 }
  let yoe = y - era * 400
  let mp = if m0 > 2 { m0 - 3 } else { m0 + 9 }
  let doy = (153 * mp + 2) / 5 + d - 1
  let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
  era * 146097 + doe - 719468
}

///|
fn civil_from_days(z0 : Int) -> (Int, Int, Int) {
  let z = z0 + 719468
  let era = if z >= 0 { z / 146097 } else { (z - 146096) / 146097 }
  let doe = z - era * 146097
  let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
  let y = yoe + era * 400
  let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
  let mp = (5 * doy + 2) / 153
  let d = doy - (153 * mp + 2) / 5 + 1
  let m = mp + (if mp < 10 { 3 } else { -9 })
  let y = y + (if m <= 2 { 1 } else { 0 })
  (y, m, d)
}
