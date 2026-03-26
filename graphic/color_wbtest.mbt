// Corresponds to: zrender/src/tool/color.ts
// White-box tests for the Color type in graphic/color.mbt.

///|
test "color from_hex #rrggbb" {
  let c = Color::from_hex("#5470c6")
  assert_eq(c, Some({ r: 0x54, g: 0x70, b: 0xc6, a: 255 }))
}

///|
test "color from_hex #rgb shorthand" {
  let c = Color::from_hex("#f80")
  // 'f' → 15 * 17 = 255, '8' → 8 * 17 = 136, '0' → 0
  assert_eq(c, Some({ r: 255, g: 136, b: 0, a: 255 }))
}

///|
test "color from_hex #rrggbbaa" {
  let c = Color::from_hex("#ff000080")
  assert_eq(c, Some({ r: 255, g: 0, b: 0, a: 128 }))
}

///|
test "color from_hex invalid" {
  assert_eq(Color::from_hex("#xyz"), None)
  assert_eq(Color::from_hex("nothex"), None)
  assert_eq(Color::from_hex("#12"), None)
  assert_eq(Color::from_hex(""), None)
}

///|
test "color from_string named" {
  assert_eq(Color::from_string("black"), Some({ r: 0, g: 0, b: 0, a: 255 }))
  assert_eq(
    Color::from_string("white"),
    Some({ r: 255, g: 255, b: 255, a: 255 }),
  )
  assert_eq(Color::from_string("red"), Some({ r: 255, g: 0, b: 0, a: 255 }))
  assert_eq(Color::from_string("transparent"), Some({ r: 0, g: 0, b: 0, a: 0 }))
}

///|
test "color from_string hex fallback" {
  // Named colors not in the table fall through to from_hex
  let c = Color::from_string("#91cc75")
  assert_eq(c, Some({ r: 0x91, g: 0xcc, b: 0x75, a: 255 }))
}

///|
test "color from_string unknown" {
  assert_eq(Color::from_string("cornflowerblue"), None)
  assert_eq(Color::from_string(""), None)
}

///|
test "color lerp half" {
  let a = Color::rgb(0, 0, 0)
  let b = Color::rgb(100, 200, 50)
  let mid = Color::lerp(a, b, 0.5)
  assert_eq(mid.r, 50)
  assert_eq(mid.g, 100)
  assert_eq(mid.b, 25)
  assert_eq(mid.a, 255)
}

///|
test "color lerp t=0 and t=1" {
  let a = Color::rgb(10, 20, 30)
  let b = Color::rgb(110, 120, 130)
  let at0 = Color::lerp(a, b, 0.0)
  assert_eq(at0.r, 10)
  assert_eq(at0.g, 20)
  assert_eq(at0.b, 30)
  let at1 = Color::lerp(a, b, 1.0)
  assert_eq(at1.r, 110)
  assert_eq(at1.g, 120)
  assert_eq(at1.b, 130)
}

///|
test "color to_svg opaque" {
  let c = Color::rgb(84, 112, 198)
  assert_eq(c.to_svg(), "#5470c6")
}

///|
test "color to_svg transparent" {
  assert_eq(transparent.to_svg(), "none")
}

///|
test "color to_svg semi-transparent" {
  // rgba with a=128 → "rgba(255,0,0,0.502)" approximately; just check prefix
  let c = Color::rgba(255, 0, 0, 128)
  let s = c.to_svg()
  assert_true(s.has_prefix("rgba("))
}

///|
test "color rgb constructor" {
  let c = Color::rgb(1, 2, 3)
  assert_eq(c.r, 1)
  assert_eq(c.g, 2)
  assert_eq(c.b, 3)
  assert_eq(c.a, 255)
}

///|
test "color rgba constructor" {
  let c = Color::rgba(10, 20, 30, 100)
  assert_eq(c.r, 10)
  assert_eq(c.g, 20)
  assert_eq(c.b, 30)
  assert_eq(c.a, 100)
}
