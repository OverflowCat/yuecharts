// Corresponds to: echarts/src/data/DataStore.ts

///|
pub(all) struct DataStore {
  source : Source
}

///|
pub fn DataStore::from_source(source : Source) -> DataStore {
  { source, }
}

///|
pub fn DataStore::count(self : DataStore) -> Int {
  self.source.count()
}

///|
pub fn DataStore::get_item(self : DataStore, index : Int) -> @option.DataItem? {
  if index < 0 || index >= self.source.data.length() {
    None
  } else {
    Some(self.source.data[index])
  }
}

///|
fn data_store_dimension_value(
  item : @option.DataItem,
  dim_index : Int,
) -> Double? {
  match item.value {
    @option.DataValue::Num(n) => if dim_index == 0 { Some(n) } else { None }
    @option.DataValue::DateValue(raw, n) =>
      if dim_index == 0 {
        let parsed = try? @string.parse_double(raw)
        match parsed {
          Ok(value) => Some(value)
          Err(_) => Some(n)
        }
      } else if dim_index == 1 {
        Some(n)
      } else {
        None
      }
    @option.DataValue::Vec(values) =>
      if dim_index < values.length() {
        Some(values[dim_index])
      } else {
        None
      }
    @option.DataValue::Null => None
  }
}

///|
pub fn DataStore::map_dimension_numeric_values(
  self : DataStore,
  dim_index : Int,
) -> Array[Double?] {
  let result : Array[Double?] = []
  let mut i = 0
  while i < self.source.data.length() {
    result.push(data_store_dimension_value(self.source.data[i], dim_index))
    i += 1
  }
  result
}
