// Corresponds to: echarts/src/coord/geo/GeoSVGResource.ts
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
pub(all) enum GeoSourceResource {
  Json(GeoJSONResource)
  Svg(GeoSvgResource)
}

///|
pub struct GeoSourceManager {
  resources : Array[GeoSourceResource]
}

///|
let global_geo_source_manager : GeoSourceManager = GeoSourceManager::{
  resources: [],
}

///|
pub fn GeoSourceManager::from_option(
  opt : @option.ChartOption,
) -> GeoSourceManager {
  let resources = global_geo_source_manager.resources
  for j, _ in opt.map_registry {
    let entry = opt.map_registry[j]
    match entry.svg {
      Some(svg) =>
        resources.push(GeoSourceResource::Svg({ map_name: entry.name, svg }))
      None =>
        match entry.geo_json {
          Some(geo_json) =>
            resources.push(
              GeoSourceResource::Json({
                map_name: entry.name,
                geo_json,
                special_areas: entry.special_areas,
              }),
            )
          None => ()
        }
    }
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
  match geo_json {
    Object(map) =>
      match map.get("svg") {
        Some(String(svg)) =>
          self.resources.push(GeoSourceResource::Svg({ map_name, svg }))
        _ =>
          self.resources.push(
            GeoSourceResource::Json({ map_name, geo_json, special_areas }),
          )
      }
    _ =>
      self.resources.push(
        GeoSourceResource::Json({ map_name, geo_json, special_areas }),
      )
  }
}

///|
pub fn GeoSourceManager::get_geo_resource(
  self : GeoSourceManager,
  map_name : String,
) -> GeoSourceResource? {
  let mut i = self.resources.length()
  while i > 0 {
    i -= 1
    let resource = self.resources[i]
    match resource {
      Json(json_resource) =>
        if json_resource.map_name == map_name {
          return Some(resource)
        }
      Svg(svg_resource) =>
        if svg_resource.map_name == map_name {
          return Some(resource)
        }
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
    Some(Json(resource)) => Some(resource.get_map_for_user())
    _ => None
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
pub fn GeoSourceResource::load(
  self : GeoSourceResource,
  name_map : Array[@option.GeoNameMapEntry],
  name_property : String,
) -> GeoLoadedResource {
  match self {
    Json(resource) => resource.load(name_map, name_property)
    Svg(resource) => resource.load(name_map, name_property)
  }
}
