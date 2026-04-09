// Whitebox tests for data/source.mbt, data/data_store.mbt, and data/series_data.mbt.

///|
test "series data wraps original themeRiver rows" {
  let json_str =
    #|{
    #|  "singleAxis": {},
    #|  "series": [{
    #|    "type": "themeRiver",
    #|    "data": [[0, 2, "A"], [2, 4, "A"]]
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let data = SeriesData::from_series(opt.series[0])
  assert_eq(data.count(), 2)
  assert_true(data.source.source_format == SourceFormat::Original)
  assert_eq(data.dimensions, ["single", "value"])
  assert_eq(data.map_dimension_numeric_values(0), [Some(0.0), Some(2.0)])
  assert_eq(data.map_dimension_numeric_values(1), [Some(2.0), Some(4.0)])
}

///|
test "data store returns none for out of range items" {
  let json_str =
    #|{
    #|  "series": [{
    #|    "type": "line",
    #|    "data": [1, 2, 3]
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let data = SeriesData::from_series(opt.series[0])
  assert_true(data.get_item(10) is None)
}
