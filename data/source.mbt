// Corresponds to: echarts/src/data/Source.ts

///|
pub(all) enum SourceFormat {
  Original
  ArrayRows
  ObjectRows
  KeyedColumns
  TypedArray
  Unknown
} derive(Eq)

///|
pub(all) struct DimensionDefinition {
  name : String
}

///|
pub(all) struct SourceMetaRawOption {
  series_layout_by : String
  source_header : Int
  dimensions : Array[DimensionDefinition]
}

///|
pub(all) struct Source {
  data : Array[@option.DataItem]
  source_format : SourceFormat
  dimensions_define : Array[DimensionDefinition]
  start_index : Int
  dimensions_detected_count : Int
  meta_raw_option : SourceMetaRawOption?
}

///|
pub fn create_source_from_series_data_option(
  data : Array[@option.DataItem],
) -> Source {
  {
    data,
    source_format: SourceFormat::Original,
    dimensions_define: [],
    start_index: 0,
    dimensions_detected_count: 0,
    meta_raw_option: None,
  }
}

///|
pub fn Source::clone_shallow(self : Source) -> Source {
  {
    data: self.data,
    source_format: self.source_format,
    dimensions_define: self.dimensions_define,
    start_index: self.start_index,
    dimensions_detected_count: self.dimensions_detected_count,
    meta_raw_option: self.meta_raw_option,
  }
}

///|
pub fn Source::count(self : Source) -> Int {
  self.data.length()
}
