// Corresponds to: echarts/src/coord/geo/GeoJSONResource.ts
//                  echarts/src/coord/geo/geoSourceManager.ts

///|
pub(all) struct GeoLoadedResource {
  regions : Array[GeoRegion]
  bounding_rect : @graphic.BBox
}

///|
pub(all) struct GeoMapForUser {
  geo_json : Json
  special_areas : Array[@option.MapSpecialAreaOption]
}

///|
pub struct GeoJsonResource {
  map_name : String
  geo_json : Json
  special_areas : Array[@option.MapSpecialAreaOption]
}

///|
pub struct GeoSourceManager {
  resources : Array[GeoJsonResource]
}

///|
let global_geo_source_manager : GeoSourceManager = GeoSourceManager::{
  resources: [],
}

///|
pub fn GeoSourceManager::from_option(
  opt : @option.ChartOption,
) -> GeoSourceManager {
  let resources : Array[GeoJsonResource] = []
  let mut i = 0
  while i < global_geo_source_manager.resources.length() {
    resources.push(global_geo_source_manager.resources[i])
    i += 1
  }
  let mut j = 0
  while j < opt.map_registry.length() {
    let entry = opt.map_registry[j]
    match entry.geo_json {
      Some(geo_json) =>
        resources.push({
          map_name: entry.name,
          geo_json,
          special_areas: entry.special_areas,
        })
      None => ()
    }
    j += 1
  }
  { resources, }
}

///|
pub fn register_global_map(
  map_name : String,
  geo_json : Json,
  special_areas : Array[@option.MapSpecialAreaOption],
) -> Unit {
  global_geo_source_manager.register_map(map_name, geo_json, special_areas)
}

///|
pub fn get_global_map_for_user(map_name : String) -> GeoMapForUser? {
  global_geo_source_manager.get_map_for_user(map_name)
}

///|
pub fn GeoSourceManager::register_map(
  self : GeoSourceManager,
  map_name : String,
  geo_json : Json,
  special_areas : Array[@option.MapSpecialAreaOption],
) -> Unit {
  self.resources.push({ map_name, geo_json, special_areas })
}

///|
pub fn GeoSourceManager::get_geo_resource(
  self : GeoSourceManager,
  map_name : String,
) -> GeoJsonResource? {
  let mut i = self.resources.length()
  while i > 0 {
    i -= 1
    let resource = self.resources[i]
    if resource.map_name == map_name {
      return Some(resource)
    }
  }
  None
}

///|
pub fn GeoSourceManager::get_map_for_user(
  self : GeoSourceManager,
  map_name : String,
) -> GeoMapForUser? {
  match self.get_geo_resource(map_name) {
    Some(resource) =>
      Some({
        geo_json: resource.geo_json,
        special_areas: resource.special_areas,
      })
    None => None
  }
}

///|
pub fn GeoSourceManager::load(
  self : GeoSourceManager,
  map_name : String,
  name_map : Array[@option.GeoNameMapEntry],
  name_property : String,
) -> GeoLoadedResource? {
  match self.get_geo_resource(map_name) {
    Some(resource) => Some(resource.load(name_map, name_property))
    None => None
  }
}

///|
pub fn GeoJsonResource::load(
  self : GeoJsonResource,
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
