// Corresponds to: echarts/src/chart/pie/PieSeries.ts
// White-box tests for pie option parsing.

///|
test "pie roseType parses radius and area" {
  let radius_series = parse_series_option(
    @json.parse(
      (
        #|{
        #|  "type": "pie",
        #|  "roseType": "radius"
        #|}
      ),
    ),
  )
  assert_eq(radius_series.pie_rose_type, Some("radius"))

  let area_series = parse_series_option(
    @json.parse(
      (
        #|{
        #|  "type": "pie",
        #|  "roseType": "area"
        #|}
      ),
    ),
  )
  assert_eq(area_series.pie_rose_type, Some("area"))
}

///|
test "pie roseType ignores unsupported values" {
  let series = parse_series_option(
    @json.parse(
      (
        #|{
        #|  "type": "pie",
        #|  "roseType": "not-supported"
        #|}
      ),
    ),
  )
  assert_eq(series.pie_rose_type, None)
}
