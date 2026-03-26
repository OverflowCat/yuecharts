// Corresponds to: echarts/src/scale/Ordinal.ts

///|
/// Ordinal scale: maps discrete categories to pixel bands.
pub struct OrdinalScale {
  categories : Array[String]
  range_min : Double
  range_max : Double
  padding : Double // 0–1, proportion of band width used as padding
}

///|
pub fn OrdinalScale::new(
  categories : Array[String],
  range_min : Double,
  range_max : Double,
  padding : Double,
) -> OrdinalScale {
  { categories, range_min, range_max, padding }
}

///|
/// Width of each band (including padding).
pub fn OrdinalScale::band_step(self : OrdinalScale) -> Double {
  let n = self.categories.length()
  if n == 0 {
    0.0
  } else {
    (self.range_max - self.range_min) / n.to_double()
  }
}

///|
/// Width of the actual rendered band (excluding padding).
pub fn OrdinalScale::band_width(self : OrdinalScale) -> Double {
  self.band_step() * (1.0 - self.padding)
}

///|
/// Get the center pixel position of a category.
pub fn OrdinalScale::band_center(self : OrdinalScale, index : Int) -> Double {
  self.range_min + (index.to_double() + 0.5) * self.band_step()
}

///|
/// Get the start of a band (left/top edge).
pub fn OrdinalScale::band_start(self : OrdinalScale, index : Int) -> Double {
  let half_pad = self.band_step() * self.padding * 0.5
  self.range_min + index.to_double() * self.band_step() + half_pad
}

///|
/// Find the index of a category, returning None if not found.
pub fn OrdinalScale::index_of(self : OrdinalScale, category : String) -> Int? {
  let mut found = -1
  for i, cat in self.categories {
    if cat == category {
      found = i
      break
    }
  }
  if found >= 0 {
    Some(found)
  } else {
    None
  }
}

///|
/// Map a category string to its center pixel.
pub fn OrdinalScale::data_to_pixel(
  self : OrdinalScale,
  category : String,
) -> Double? {
  self.index_of(category).map(index => self.band_center(index))
}

///|
/// Generate tick labels with positions (at band centers).
pub fn OrdinalScale::ticks(self : OrdinalScale) -> Array[Tick] {
  self.categories
  .iter()
  .mapi((i, cat) => { value: self.band_center(i), label: cat })
  .collect()
}
