// Corresponds to: echarts/src/coord/geo/GeoJSONResource.ts

///|
pub struct GeoJSONResource {
  map_name : String
  geo_json : Json
  special_areas : Array[@option.MapSpecialAreaOption]
}

///|
pub fn GeoJSONResource::load(
  self : GeoJSONResource,
  name_map : Array[@option.GeoNameMapEntry],
  name_property : String,
) -> GeoLoadedResource {
  let regions = apply_geo_name_map(
    apply_geo_special_areas(
      parse_geo_json(self.geo_json, name_property),
      self.special_areas,
    ),
    name_map,
  )
  { regions, bounding_rect: geo_regions_bounding_rect(regions) }
}

///|
pub fn GeoJSONResource::get_map_for_user(
  self : GeoJSONResource,
) -> GeoMapForUser {
  { geo_json: self.geo_json, special_areas: self.special_areas }
}

///|
fn geo_regions_bounding_rect(regions : Array[GeoRegion]) -> @graphic.BBox {
  if regions.length() == 0 {
    return @graphic.BBox::new(0.0, 0.0, 0.0, 0.0)
  }
  let mut min_x = regions[0].data_bbox.x
  let mut max_x = regions[0].data_bbox.x + regions[0].data_bbox.width
  let mut min_y = regions[0].data_bbox.y
  let mut max_y = regions[0].data_bbox.y + regions[0].data_bbox.height
  let mut i = 1
  while i < regions.length() {
    let bbox = regions[i].data_bbox
    if bbox.x < min_x {
      min_x = bbox.x
    }
    if bbox.x + bbox.width > max_x {
      max_x = bbox.x + bbox.width
    }
    if bbox.y < min_y {
      min_y = bbox.y
    }
    if bbox.y + bbox.height > max_y {
      max_y = bbox.y + bbox.height
    }
    i += 1
  }
  @graphic.BBox::new(min_x, min_y, max_x - min_x, max_y - min_y)
}
