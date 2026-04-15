// Corresponds to: zrender/src/tool/path.ts
// and zrender/src/graphic/shape/Rect.ts (rounded corners)

///|
/// Build a rounded-rectangle SVG path string.
pub fn round_rect_path(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  r : Double,
) -> String {
  let rr = if r < w / 2.0 {
    if r < h / 2.0 {
      r
    } else {
      h / 2.0
    }
  } else if w / 2.0 < h / 2.0 {
    w / 2.0
  } else {
    h / 2.0
  }
  "M \{x + rr} \{y} L \{x + w - rr} \{y} Q \{x + w} \{y} \{x + w} \{y + rr} L \{x + w} \{y + h - rr} Q \{x + w} \{y + h} \{x + w - rr} \{y + h} L \{x + rr} \{y + h} Q \{x} \{y + h} \{x} \{y + h - rr} L \{x} \{y + rr} Q \{x} \{y} \{x + rr} \{y} Z"
}

///|
pub fn is_path_command(ch : Char) -> Bool {
  match ch {
    'M'
    | 'm'
    | 'L'
    | 'l'
    | 'H'
    | 'h'
    | 'V'
    | 'v'
    | 'C'
    | 'c'
    | 'S'
    | 's'
    | 'Q'
    | 'q'
    | 'T'
    | 't'
    | 'A'
    | 'a'
    | 'Z'
    | 'z' => true
    _ => false
  }
}

///|
pub fn is_number_char(ch : Char) -> Bool {
  (ch >= '0' && ch <= '9') ||
  ch == '-' ||
  ch == '+' ||
  ch == '.' ||
  ch == 'e' ||
  ch == 'E'
}

///|
pub fn skip_path_separators(d : String, start : Int) -> Int {
  let mut i = start
  while i < d.length() {
    let ch = d[i].unsafe_to_char()
    if ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t' || ch == ',' {
      i += 1
    } else {
      break
    }
  }
  i
}

///|
pub fn parse_path_number(d : String, start : Int) -> (Double, Int)? {
  let i0 = skip_path_separators(d, start)
  if i0 >= d.length() || !is_number_char(d[i0].unsafe_to_char()) {
    return None
  }
  let mut i = i0
  if d[i].unsafe_to_char() == '+' || d[i].unsafe_to_char() == '-' {
    i += 1
  }
  while i < d.length() &&
        d[i].unsafe_to_char() >= '0' &&
        d[i].unsafe_to_char() <= '9' {
    i += 1
  }
  if i < d.length() && d[i].unsafe_to_char() == '.' {
    i += 1
    while i < d.length() &&
          d[i].unsafe_to_char() >= '0' &&
          d[i].unsafe_to_char() <= '9' {
      i += 1
    }
  }
  if i < d.length() &&
    (d[i].unsafe_to_char() == 'e' || d[i].unsafe_to_char() == 'E') {
    i += 1
    if i < d.length() &&
      (d[i].unsafe_to_char() == '+' || d[i].unsafe_to_char() == '-') {
      i += 1
    }
    while i < d.length() &&
          d[i].unsafe_to_char() >= '0' &&
          d[i].unsafe_to_char() <= '9' {
      i += 1
    }
  }
  try @string.parse_double(d[i0:i].to_string()) catch {
    _ => None
  } noraise {
    value => Some((value, i))
  }
}

///|
pub fn update_path_bbox(
  point : (Double, Double),
  bbox : (Double, Double, Double, Double)?,
) -> (Double, Double, Double, Double) {
  let (x, y) = point
  match bbox {
    Some((min_x, min_y, max_x, max_y)) =>
      (
        if x < min_x {
          x
        } else {
          min_x
        },
        if y < min_y {
          y
        } else {
          min_y
        },
        if x > max_x {
          x
        } else {
          max_x
        },
        if y > max_y {
          y
        } else {
          max_y
        },
      )
    None => (x, y, x, y)
  }
}

///|
/// Compute the bounding box of an SVG path by walking its commands.
pub fn path_bbox(d : String) -> (Double, Double, Double, Double)? {
  let mut i = 0
  let mut cmd = ' '
  let mut bbox : (Double, Double, Double, Double)? = None
  let mut cur_x = 0.0
  let mut cur_y = 0.0
  let mut start_x = 0.0
  let mut start_y = 0.0
  while i < d.length() {
    i = skip_path_separators(d, i)
    if i >= d.length() {
      break
    }
    if is_path_command(d[i].unsafe_to_char()) {
      cmd = d[i].unsafe_to_char()
      i += 1
      if cmd == 'Z' || cmd == 'z' {
        cur_x = start_x
        cur_y = start_y
      }
      continue
    }
    match cmd {
      'M' | 'm' => {
        guard parse_path_number(d, i) is Some((x0, i1)) else { break }
        guard parse_path_number(d, i1) is Some((y0, i2)) else { break }
        let x = if cmd == 'm' { cur_x + x0 } else { x0 }
        let y = if cmd == 'm' { cur_y + y0 } else { y0 }
        cur_x = x
        cur_y = y
        start_x = x
        start_y = y
        bbox = Some(update_path_bbox((x, y), bbox))
        i = i2
        cmd = if cmd == 'm' { 'l' } else { 'L' }
      }
      'L' | 'l' => {
        guard parse_path_number(d, i) is Some((x0, i1)) else { break }
        guard parse_path_number(d, i1) is Some((y0, i2)) else { break }
        let x = if cmd == 'l' { cur_x + x0 } else { x0 }
        let y = if cmd == 'l' { cur_y + y0 } else { y0 }
        bbox = Some(update_path_bbox((x, y), bbox))
        cur_x = x
        cur_y = y
        i = i2
      }
      'H' | 'h' =>
        match parse_path_number(d, i) {
          Some((x0, i1)) => {
            let x = if cmd == 'h' { cur_x + x0 } else { x0 }
            bbox = Some(update_path_bbox((x, cur_y), bbox))
            cur_x = x
            i = i1
          }
          None => break
        }
      'V' | 'v' => {
        guard parse_path_number(d, i) is Some((y0, i1)) else { break }
        let y = if cmd == 'v' { cur_y + y0 } else { y0 }
        bbox = Some(update_path_bbox((cur_x, y), bbox))
        cur_y = y
        i = i1
      }
      'C' | 'c' => {
        guard parse_path_number(d, i) is Some((x1, i1)) else { break }
        guard parse_path_number(d, i1) is Some((y1, i2)) else { break }
        guard parse_path_number(d, i2) is Some((x2, i3)) else { break }
        guard parse_path_number(d, i3) is Some((y2, i4)) else { break }
        guard parse_path_number(d, i4) is Some((x3, i5)) else { break }
        guard parse_path_number(d, i5) is Some((y3, i6)) else { break }
        let ax1 = if cmd == 'c' { cur_x + x1 } else { x1 }
        let ay1 = if cmd == 'c' { cur_y + y1 } else { y1 }
        let ax2 = if cmd == 'c' { cur_x + x2 } else { x2 }
        let ay2 = if cmd == 'c' { cur_y + y2 } else { y2 }
        let ax3 = if cmd == 'c' { cur_x + x3 } else { x3 }
        let ay3 = if cmd == 'c' { cur_y + y3 } else { y3 }
        bbox = Some(update_path_bbox((ax1, ay1), bbox))
        bbox = Some(update_path_bbox((ax2, ay2), bbox))
        bbox = Some(update_path_bbox((ax3, ay3), bbox))
        cur_x = ax3
        cur_y = ay3
        i = i6
      }
      'S' | 's' | 'Q' | 'q' => {
        let needed = 4
        let values : Array[Double] = []
        let mut next_i = i
        let mut ok = true
        let mut vi = 0
        while vi < needed {
          match parse_path_number(d, next_i) {
            Some((value, parsed_i)) => {
              values.push(value)
              next_i = parsed_i
            }
            None => {
              ok = false
              vi = needed
            }
          }
          vi += 1
        }
        if !ok {
          break
        }
        let pairs = [(values[0], values[1]), (values[2], values[3])]
        let mut pi = 0
        while pi < pairs.length() {
          let (px0, py0) = pairs[pi]
          let px = if cmd == 's' || cmd == 'q' { cur_x + px0 } else { px0 }
          let py = if cmd == 's' || cmd == 'q' { cur_y + py0 } else { py0 }
          bbox = Some(update_path_bbox((px, py), bbox))
          if pi == pairs.length() - 1 {
            cur_x = px
            cur_y = py
          }
          pi += 1
        }
        i = next_i
      }
      'T' | 't' => {
        guard parse_path_number(d, i) is Some((x0, i1)) else { break }
        guard parse_path_number(d, i1) is Some((y0, i2)) else { break }
        let x = if cmd == 't' { cur_x + x0 } else { x0 }
        let y = if cmd == 't' { cur_y + y0 } else { y0 }
        bbox = Some(update_path_bbox((x, y), bbox))
        cur_x = x
        cur_y = y
        i = i2
      }
      'A' | 'a' => {
        let values : Array[Double] = []
        let mut next_i = i
        let mut ok = true
        let mut vi = 0
        while vi < 7 {
          match parse_path_number(d, next_i) {
            Some((value, parsed_i)) => {
              values.push(value)
              next_i = parsed_i
            }
            None => {
              ok = false
              vi = 7
            }
          }
          vi += 1
        }
        if !ok {
          break
        }
        let end_x = if cmd == 'a' { cur_x + values[5] } else { values[5] }
        let end_y = if cmd == 'a' { cur_y + values[6] } else { values[6] }
        bbox = Some(update_path_bbox((end_x, end_y), bbox))
        bbox = Some(
          update_path_bbox((end_x + values[0], end_y + values[1]), bbox),
        )
        bbox = Some(
          update_path_bbox((end_x - values[0], end_y - values[1]), bbox),
        )
        cur_x = end_x
        cur_y = end_y
        i = next_i
      }
      _ => i += 1
    }
  }
  bbox
}

///|
/// Fallback bbox by scanning all numeric pairs when path commands are unparseable.
pub fn fallback_path_bbox(d : String) -> (Double, Double, Double, Double)? {
  let values : Array[Double] = []
  let mut i = 0
  while i < d.length() {
    match parse_path_number(d, i) {
      Some((value, next_i)) => {
        values.push(value)
        i = next_i
      }
      None => i += 1
    }
  }
  if values.length() < 2 {
    return None
  }
  let mut bbox : (Double, Double, Double, Double)? = None
  let mut vi = 0
  while vi + 1 < values.length() {
    bbox = Some(update_path_bbox((values[vi], values[vi + 1]), bbox))
    vi += 2
  }
  bbox
}
