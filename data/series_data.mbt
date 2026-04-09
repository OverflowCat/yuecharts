// Corresponds to: echarts/src/data/SeriesData.ts

///|
pub(all) struct SeriesData {
  host_series_type : @option.SeriesType
  dimensions : Array[String]
  source : Source
  store : DataStore
}

///|
fn series_data_dimensions(series : @option.SeriesOption) -> Array[String] {
  match series.series_type {
    @option.SeriesType::ThemeRiver => ["single", "value"]
    @option.SeriesType::Parallel => ["parallel"]
    @option.SeriesType::Lines => ["value"]
    _ => ["value"]
  }
}

///|
pub fn SeriesData::from_series(series : @option.SeriesOption) -> SeriesData {
  let source = create_source_from_series_data_option(series.data)
  let store = DataStore::from_source(source)
  {
    host_series_type: series.series_type,
    dimensions: series_data_dimensions(series),
    source,
    store,
  }
}

///|
pub fn SeriesData::count(self : SeriesData) -> Int {
  self.store.count()
}

///|
pub fn SeriesData::get_item(
  self : SeriesData,
  index : Int,
) -> @option.DataItem? {
  self.store.get_item(index)
}

///|
pub fn SeriesData::raw_items(self : SeriesData) -> Array[@option.DataItem] {
  self.source.data
}

///|
pub fn SeriesData::map_dimension_numeric_values(
  self : SeriesData,
  dim_index : Int,
) -> Array[Double?] {
  self.store.map_dimension_numeric_values(dim_index)
}
