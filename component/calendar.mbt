// Corresponds to: echarts/src/component/calendar/CalendarView.ts

///|
let weekday_short_names : Array[String] = ["S", "M", "T", "W", "T", "F", "S"]

///|
let month_abbr_names : Array[String] = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
]

///|
pub struct CalendarRenderState {
  tlpoints : Array[@graphic.Point]
  blpoints : Array[@graphic.Point]
  first_day_of_month : Array[@coord.CalendarParsedDateInfo]
  first_day_points : Array[@graphic.Point]
}

///|
fn empty_calendar_render_state() -> CalendarRenderState {
  { tlpoints: [], blpoints: [], first_day_of_month: [], first_day_points: [] }
}

///|
pub fn render_calendar(
  opt : @option.ChartOption,
  calendar? : @coord.Calendar,
) -> Array[@graphic.Element] {
  let calendar = match calendar {
    Some(value) => value
    None => return []
  }
  if opt.calendar.length() == 0 {
    return []
  }
  let calendar_model = opt.calendar[0]
  let range_data = calendar.get_range_info()
  let orient = calendar.get_orient()
  let elems : Array[@graphic.Element] = []
  render_day_rect(calendar_model, calendar, range_data, elems)
  let line_state = render_lines(
    calendar_model, calendar, range_data, orient, elems,
  )
  render_year_text(calendar_model, range_data, orient, line_state, elems)
  render_month_text(calendar_model, orient, line_state, elems)
  render_week_text(calendar_model, calendar, range_data, orient, elems)
  elems
}

///|
fn render_day_rect(
  calendar_model : @option.CalendarOption,
  coord_sys : @coord.Calendar,
  range_data : @coord.CalendarParsedDateRangeInfo,
  elems : Array[@graphic.Element],
) -> Unit {
  let sw = coord_sys.get_cell_width()
  let sh = coord_sys.get_cell_height()
  let item_style = calendar_model.item_style
  let mut current = range_data.start.formated_date
  while true {
    let point = coord_sys.data_to_calendar_layout(current, clamp=false).tl
    elems.push(
      @graphic.Element::rect_fill_stroke(
        point.x,
        point.y,
        sw,
        sh,
        item_style.color,
        item_style.border_color,
        item_style.border_width,
      ),
    )
    if current == range_data.end.formated_date {
      break
    }
    current = coord_sys.get_next_n_day(current, 1).formated_date
  }
}

///|
fn render_lines(
  calendar_model : @option.CalendarOption,
  coord_sys : @coord.Calendar,
  range_data : @coord.CalendarParsedDateRangeInfo,
  orient : String,
  elems : Array[@graphic.Element],
) -> CalendarRenderState {
  let line_style = calendar_model.split_line
  let show = line_style.show
  let line_width = line_style.width
  let state = empty_calendar_render_state()
  let mut first_day = range_data.start
  let mut i = 0
  while first_day.time <= range_data.end.time {
    add_line_points(
      state,
      calendar_model,
      coord_sys,
      first_day.formated_date,
      orient,
      show,
      elems,
    )
    if i == 0 {
      first_day = coord_sys.get_date_info(
        range_data.start.y + "-" + range_data.start.m,
      )
    }
    let next = next_month(
      to_int_or(first_day.y, 1970),
      to_int_or(first_day.m, 1),
    )
    first_day = coord_sys.get_date_info(format_date(next.0, next.1, 1))
    i += 1
  }
  add_line_points(
    state,
    calendar_model,
    coord_sys,
    coord_sys.get_next_n_day(range_data.end.formated_date, 1).formated_date,
    orient,
    show,
    elems,
  )
  if show && state.tlpoints.length() > 0 {
    draw_splitline(
      get_edges_points(state.tlpoints, line_width, orient),
      line_style,
      elems,
    )
    draw_splitline(
      get_edges_points(state.blpoints, line_width, orient),
      line_style,
      elems,
    )
  }
  state
}

///|
fn add_line_points(
  state : CalendarRenderState,
  calendar_model : @option.CalendarOption,
  coord_sys : @coord.Calendar,
  date : String,
  orient : String,
  show : Bool,
  elems : Array[@graphic.Element],
) -> Unit {
  state.first_day_of_month.push(coord_sys.get_date_info(date))
  state.first_day_points.push(
    coord_sys.data_to_calendar_layout(date, clamp=false).tl,
  )
  let points = get_line_points_of_one_week(
    calendar_model, coord_sys, date, orient,
  )
  state.tlpoints.push(points[0])
  state.blpoints.push(points[points.length() - 1])
  if show {
    draw_splitline(points, calendar_model.split_line, elems)
  }
}

///|
fn get_edges_points(
  points : Array[@graphic.Point],
  line_width : Double,
  orient : String,
) -> Array[@graphic.Point] {
  let first = points[0]
  let last = points[points.length() - 1]
  if orient == "horizontal" {
    [
      @graphic.Point::new(first.x - line_width / 2.0, first.y),
      @graphic.Point::new(last.x + line_width / 2.0, last.y),
    ]
  } else {
    [
      @graphic.Point::new(first.x, first.y - line_width / 2.0),
      @graphic.Point::new(last.x, last.y + line_width / 2.0),
    ]
  }
}

///|
fn draw_splitline(
  points : Array[@graphic.Point],
  line_style : @option.CalendarSplitLineOption,
  elems : Array[@graphic.Element],
) -> Unit {
  elems.push(
    @graphic.Element::polyline_custom(
      points,
      line_style.color,
      line_style.width,
      "butt",
      "miter",
    ),
  )
}

///|
fn get_line_points_of_one_week(
  _calendar_model : @option.CalendarOption,
  coord_sys : @coord.Calendar,
  date : String,
  orient : String,
) -> Array[@graphic.Point] {
  let parsed_date = coord_sys.get_date_info(date)
  let nan = 0.0 / 0.0
  let slots : Array[@graphic.Point] = []
  let mut j = 0
  while j < 14 {
    slots.push(@graphic.Point::new(nan, nan))
    j += 1
  }
  let mut i = 0
  while i < 7 {
    let tmp_d = coord_sys.get_next_n_day(parsed_date.formated_date, i)
    let point = coord_sys.data_to_calendar_layout(
      tmp_d.formated_date,
      clamp=false,
    )
    slots[2 * tmp_d.day] = point.tl
    slots[2 * tmp_d.day + 1] = if orient == "horizontal" {
      point.bl
    } else {
      point.tr
    }
    i += 1
  }
  let points : Array[@graphic.Point] = []
  let mut k = 0
  while k < slots.length() {
    let point = slots[k]
    if point.x == point.x && point.y == point.y {
      points.push(point)
    }
    k += 1
  }
  points
}

///|
fn formatter_label(
  formatter : String?,
  params : Array[(String, String)],
  fallback : String,
) -> String {
  match formatter {
    Some(value) if value != "" => {
      let mut result = value
      let mut i = 0
      while i < params.length() {
        let (key, val) = params[i]
        result = result.replace(old="{" + key + "}", new=val)
        i += 1
      }
      result
    }
    _ => fallback
  }
}

///|
fn render_year_text(
  calendar_model : @option.CalendarOption,
  range_data : @coord.CalendarParsedDateRangeInfo,
  orient : String,
  line_state : CalendarRenderState,
  elems : Array[@graphic.Element],
) -> Unit {
  let year_label = calendar_model.year_label
  if !year_label.show ||
    line_state.tlpoints.length() == 0 ||
    line_state.blpoints.length() == 0 {
    return
  }
  let margin = year_label.margin
  let pos = match year_label.position {
    Some(value) => value
    None => if orient != "horizontal" { "top" } else { "left" }
  }
  let last_tl = line_state.tlpoints[line_state.tlpoints.length() - 1]
  let first_bl = line_state.blpoints[0]
  let xc = (last_tl.x + first_bl.x) / 2.0
  let yc = (last_tl.y + first_bl.y) / 2.0
  let idx = if orient == "horizontal" { 0 } else { 1 }
  let pos_point = match pos {
    "top" =>
      if idx == 0 {
        @graphic.Point::new(xc, last_tl.y)
      } else {
        @graphic.Point::new(xc, first_bl.y)
      }
    "bottom" =>
      if idx == 0 {
        @graphic.Point::new(xc, first_bl.y)
      } else {
        @graphic.Point::new(xc, last_tl.y)
      }
    "left" =>
      if idx == 0 {
        @graphic.Point::new(first_bl.x, yc)
      } else {
        @graphic.Point::new(last_tl.x, yc)
      }
    _ =>
      if idx == 0 {
        @graphic.Point::new(last_tl.x, yc)
      } else {
        @graphic.Point::new(first_bl.x, yc)
      }
  }
  let mut name = range_data.start.y
  if to_int_or(range_data.end.y, 0) > to_int_or(range_data.start.y, 0) {
    name = name + "-" + range_data.end.y
  }
  let content = formatter_label(
    year_label.formatter,
    [
      ("start", range_data.start.y),
      ("end", range_data.end.y),
      ("nameMap", name),
    ],
    name,
  )
  elems.push(year_text_element(year_label, content, pos_point, pos, margin))
}

///|
fn year_text_element(
  label : @option.CalendarYearLabelOption,
  content : String,
  point : @graphic.Point,
  position : String,
  margin : Double,
) -> @graphic.Element {
  let mut x = point.x
  let mut y = point.y
  match position {
    "bottom" => y += margin
    "left" => x -= margin
    "right" => x += margin
    _ => y -= margin
  }
  if position == "left" || position == "right" {
    let inner_y = if position == "left" {
      -label.font_size / 2.0
    } else {
      label.font_size / 2.0
    }
    let text = @graphic.Element::text_custom(
      0.0,
      inner_y,
      content,
      @graphic.TextAnchor::Middle,
      @graphic.TextBaseline::Central,
      label.color,
      label.font_size,
      label.font_family,
      label.font_weight,
    )
    let transform = @graphic.Matrix::translate(x, y).then(
      @graphic.Matrix::rotate(-3.141592653589793 / 2.0),
    )
    @graphic.Element::group_transformed([text], transform)
  } else {
    @graphic.Element::text_custom(
      x,
      y,
      content,
      @graphic.TextAnchor::Middle,
      @graphic.TextBaseline::Central,
      label.color,
      label.font_size,
      label.font_family,
      label.font_weight,
    )
  }
}

///|
fn render_month_text(
  calendar_model : @option.CalendarOption,
  orient : String,
  line_state : CalendarRenderState,
  elems : Array[@graphic.Element],
) -> Unit {
  let month_label = calendar_model.month_label
  if !month_label.show {
    return
  }
  let name_map = match month_label.name_map {
    Some(value) => value
    None => month_abbr_names
  }
  let mut margin = month_label.margin
  let pos = month_label.position
  let is_center = month_label.align == "center"
  let idx = if pos == "start" { 0 } else { 1 }
  let axis = if orient == "horizontal" { 0 } else { 1 }
  if pos == "start" {
    margin = -margin
  }
  let term_points = if idx == 0 {
    line_state.tlpoints
  } else {
    line_state.blpoints
  }
  let mut i = 0
  while i < term_points.length() - 1 {
    let mut point = term_points[i]
    let first_day = line_state.first_day_of_month[i]
    if is_center {
      let first_day_point = line_state.first_day_points[i]
      let next_point = line_state.tlpoints[i + 1]
      point = if axis == 0 {
        @graphic.Point::new((first_day_point.x + next_point.x) / 2.0, point.y)
      } else {
        @graphic.Point::new(point.x, (first_day_point.y + next_point.y) / 2.0)
      }
    }
    let month_idx = to_int_or(first_day.m, 1) - 1
    let name = if month_idx >= 0 && month_idx < name_map.length() {
      name_map[month_idx]
    } else {
      first_day.m
    }
    let yy = if first_day.y.length() >= 2 {
      first_day.y[first_day.y.length() - 2:first_day.y.length()].to_string()
    } else {
      first_day.y
    }
    let content = formatter_label(
      month_label.formatter,
      [
        ("yyyy", first_day.y),
        ("yy", yy),
        ("MM", first_day.m),
        ("M", to_int_or(first_day.m, 1).to_string()),
        ("nameMap", name),
      ],
      name,
    )
    elems.push(
      month_text_element(
        month_label, content, point, is_center, orient, pos, margin,
      ),
    )
    i += 1
  }
}

///|
fn month_text_element(
  label : @option.CalendarMonthLabelOption,
  content : String,
  point : @graphic.Point,
  is_center : Bool,
  orient : String,
  position : String,
  margin : Double,
) -> @graphic.Element {
  let mut x = point.x
  let mut y = point.y
  let mut anchor = @graphic.TextAnchor::Start
  let mut baseline = @graphic.TextBaseline::Central
  if orient == "horizontal" {
    y += margin
    if is_center {
      anchor = @graphic.TextAnchor::Middle
    }
    if position == "start" {
      y -= label.font_size / 2.0
    } else {
      y += label.font_size / 2.0
    }
  } else {
    x += margin
    if is_center {
      baseline = @graphic.TextBaseline::Central
    }
    if position == "start" {
      anchor = @graphic.TextAnchor::End
    }
  }
  @graphic.Element::text_custom(
    x,
    y,
    content,
    anchor,
    baseline,
    label.color,
    label.font_size,
    label.font_family,
    label.font_weight,
  )
}

///|
fn render_week_text(
  calendar_model : @option.CalendarOption,
  coord_sys : @coord.Calendar,
  range_data : @coord.CalendarParsedDateRangeInfo,
  orient : String,
  elems : Array[@graphic.Element],
) -> Unit {
  let day_label = calendar_model.day_label
  if !day_label.show {
    return
  }
  let pos = day_label.position
  let name_map = match day_label.name_map {
    Some(value) => value
    None => weekday_short_names
  }
  let first_day_of_week = coord_sys.get_first_day_of_week()
  let cell_size = [coord_sys.get_cell_width(), coord_sys.get_cell_height()]
  let mut margin = parse_percent(
    day_label.margin,
    if cell_size[1] < cell_size[0] {
      cell_size[1]
    } else {
      cell_size[0]
    },
  )
  let mut start = coord_sys.get_next_n_day(
      range_data.end.formated_date,
      7 - range_data.lweek,
    ).formated_date
  if pos == "start" {
    start = coord_sys.get_next_n_day(
        range_data.start.formated_date,
        -(7 + range_data.fweek),
      ).formated_date
    margin = -margin
  }
  let mut i = 0
  while i < 7 {
    let tmp_d = coord_sys.get_next_n_day(start, i)
    let point = coord_sys.data_to_calendar_layout(
        tmp_d.formated_date,
        clamp=false,
      ).center
    let day = positive_mod(i + first_day_of_week, 7)
    let content = if day < name_map.length() { name_map[day] } else { "" }
    elems.push(
      week_text_element(
        day_label, content, point, orient, pos, margin, cell_size,
      ),
    )
    i += 1
  }
}

///|
fn week_text_element(
  label : @option.CalendarDayLabelOption,
  content : String,
  point : @graphic.Point,
  orient : String,
  position : String,
  margin : Double,
  cell_size : Array[Double],
) -> @graphic.Element {
  let mut x = point.x
  let mut y = point.y
  let is_start = position == "start"
  let mut anchor = @graphic.TextAnchor::Middle
  let mut baseline = @graphic.TextBaseline::Central
  if orient == "horizontal" {
    x = x + margin + (if is_start { 1.0 } else { -1.0 }) * cell_size[0] / 2.0
    anchor = if is_start {
      @graphic.TextAnchor::End
    } else {
      @graphic.TextAnchor::Start
    }
  } else {
    y = y + margin + (if is_start { 1.0 } else { -1.0 }) * cell_size[1] / 2.0
    baseline = if is_start {
      @graphic.TextBaseline::Central
    } else {
      @graphic.TextBaseline::Central
    }
  }
  @graphic.Element::text_custom(
    x,
    y,
    content,
    anchor,
    baseline,
    label.color,
    label.font_size,
    label.font_family,
    label.font_weight,
  )
}

///|
fn parse_percent(value : String, max_value : Double) -> Double {
  if value.has_suffix("%") {
    let raw = value[:value.length() - 1].to_string()
    let parsed = try? @strconv.parse_double(raw)
    match parsed {
      Ok(v) => max_value * v / 100.0
      Err(_) => 0.0
    }
  } else {
    let parsed = try? @strconv.parse_double(value)
    match parsed {
      Ok(v) => v
      Err(_) => 0.0
    }
  }
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
fn format_date(y : Int, m : Int, d : Int) -> String {
  let mm = if m < 10 { "0\{m}" } else { m.to_string() }
  let dd = if d < 10 { "0\{d}" } else { d.to_string() }
  "\{y}-\{mm}-\{dd}"
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
fn to_int_or(value : String, fallback : Int) -> Int {
  let parsed = try? @strconv.parse_int(value)
  match parsed {
    Ok(v) => v
    Err(_) => fallback
  }
}
