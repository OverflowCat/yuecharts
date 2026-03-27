// Corresponds to: echarts/src/coord/geo/Geo.ts
//                  echarts/src/coord/geo/GeoModel.ts
//                  echarts/src/coord/geo/Region.ts
//                  echarts/src/coord/geo/parseGeoJson.ts
//                  echarts/src/coord/geo/GeoJSONResource.ts
//                  echarts/src/coord/geo/geoSourceManager.ts

///|
pub struct GeoRegion {
  name : String
  geometries : Array[GeoGeometry]
  center : @graphic.Point
  data_bbox : @graphic.BBox
}

///|
pub(all) struct GeoPolygonGeometry {
  exterior : Array[@graphic.Point]
  interiors : Array[Array[@graphic.Point]]
}

///|
pub(all) struct GeoLineStringGeometry {
  points : Array[Array[@graphic.Point]]
}

///|
pub(all) enum GeoGeometry {
  Polygon(GeoPolygonGeometry)
  LineString(GeoLineStringGeometry)
}

///|
pub struct Geo {
  map : String
  viewport : @graphic.BBox
  data_min_x : Double
  data_max_x : Double
  data_min_y : Double
  data_max_y : Double
  aspect_scale : Double
  regions : Array[GeoRegion]
}

///|
pub fn Geo::build(opt : @option.ChartOption) -> Geo? {
  if opt.geo.length() == 0 {
    return None
  }
  let geo_opt = opt.geo[0]
  if geo_opt.map == "" {
    return None
  }
  let map_entry = find_registered_map(opt.map_registry, geo_opt.map)
  map_entry.map_or(None, entry => build_geo_from_json(opt, geo_opt, entry))
}

///|
pub fn Geo::data_to_point(
  self : Geo,
  lng : Double,
  lat : Double,
) -> @graphic.Point {
  let x_span = self.data_max_x - self.data_min_x
  let y_span = self.data_max_y - self.data_min_y
  let x = if x_span == 0.0 {
    self.viewport.center_x()
  } else {
    self.viewport.x + (lng - self.data_min_x) / x_span * self.viewport.width
  }
  let projected_y = lat * self.aspect_scale
  let y = if y_span == 0.0 {
    self.viewport.center_y()
  } else {
    self.viewport.y +
    (self.data_max_y - projected_y) / y_span * self.viewport.height
  }
  @graphic.Point::new(x, y)
}

///|
pub fn Geo::region_by_name(self : Geo, name : String) -> GeoRegion? {
  let mut i = 0
  while i < self.regions.length() {
    if self.regions[i].name == name {
      return Some(self.regions[i])
    }
    i += 1
  }
  None
}

///|
pub fn GeoRegion::screen_polygon_exteriors(
  self : GeoRegion,
  geo : Geo,
) -> Array[Array[@graphic.Point]] {
  let result : Array[Array[@graphic.Point]] = []
  let mut i = 0
  while i < self.geometries.length() {
    match self.geometries[i] {
      Polygon(polygon) =>
        result.push(
          polygon.exterior.map(fn(pt) { geo.data_to_point(pt.x, pt.y) }),
        )
      _ => ()
    }
    i += 1
  }
  result
}

///|
pub fn GeoRegion::screen_polygon_rings(
  self : GeoRegion,
  geo : Geo,
) -> Array[Array[Array[@graphic.Point]]] {
  let result : Array[Array[Array[@graphic.Point]]] = []
  let mut i = 0
  while i < self.geometries.length() {
    match self.geometries[i] {
      Polygon(polygon) => {
        let rings : Array[Array[@graphic.Point]] = [
          polygon.exterior.map(fn(pt) { geo.data_to_point(pt.x, pt.y) }),
        ]
        let mut j = 0
        while j < polygon.interiors.length() {
          rings.push(
            polygon.interiors[j].map(fn(pt) { geo.data_to_point(pt.x, pt.y) }),
          )
          j += 1
        }
        result.push(rings)
      }
      _ => ()
    }
    i += 1
  }
  result
}

///|
pub fn GeoRegion::screen_center(self : GeoRegion, geo : Geo) -> @graphic.Point {
  geo.data_to_point(self.center.x, self.center.y)
}

///|
fn find_registered_map(
  maps : Array[@option.MapRegistryOption],
  name : String,
) -> @option.MapRegistryOption? {
  let mut i = 0
  while i < maps.length() {
    let item = maps[i]
    if item.name == name {
      return Some(item)
    }
    i += 1
  }
  None
}

///|
fn build_geo_from_json(
  opt : @option.ChartOption,
  geo_opt : @option.GeoOption,
  map_entry : @option.MapRegistryOption,
) -> Geo? {
  let json = match map_entry.geo_json {
    Some(value) => value
    None => return None
  }
  let aspect_scale = geo_opt.aspect_scale.unwrap_or(0.75)
  let regions = apply_geo_name_map(
    apply_geo_special_areas(parse_geo_json(json), map_entry.special_areas),
    geo_opt.name_map,
  )
  if regions.length() == 0 {
    return None
  }
  let mut min_x = 0.0
  let mut max_x = 0.0
  let mut min_y = 0.0
  let mut max_y = 0.0
  let mut first = true
  let mut i = 0
  while i < regions.length() {
    let bbox = regions[i].data_bbox
    let region_min_y = bbox.y * aspect_scale
    let region_max_y = (bbox.y + bbox.height) * aspect_scale
    if first {
      min_x = bbox.x
      max_x = bbox.x + bbox.width
      min_y = region_min_y
      max_y = region_max_y
      first = false
    } else {
      if bbox.x < min_x {
        min_x = bbox.x
      }
      if bbox.x + bbox.width > max_x {
        max_x = bbox.x + bbox.width
      }
      if region_min_y < min_y {
        min_y = region_min_y
      }
      if region_max_y > max_y {
        max_y = region_max_y
      }
    }
    i += 1
  }
  let viewport = compute_geo_viewport(opt, min_x, max_x, min_y, max_y)
  Some({
    map: geo_opt.map,
    viewport,
    data_min_x: min_x,
    data_max_x: max_x,
    data_min_y: min_y,
    data_max_y: max_y,
    aspect_scale,
    regions,
  })
}

///|
fn apply_geo_special_areas(
  regions : Array[GeoRegion],
  special_areas : Array[@option.MapSpecialAreaOption],
) -> Array[GeoRegion] {
  if special_areas.length() == 0 {
    return regions
  }
  regions.map(fn(region) {
    match geo_special_area_by_name(special_areas, region.name) {
      Some(area) =>
        geo_region_transform_to(
          region,
          area.left,
          area.top,
          area.width,
          area.height,
        )
      None => region
    }
  })
}

///|
fn geo_special_area_by_name(
  special_areas : Array[@option.MapSpecialAreaOption],
  name : String,
) -> @option.MapSpecialAreaOption? {
  let mut i = 0
  while i < special_areas.length() {
    let area = special_areas[i]
    if area.name == name {
      return Some(area)
    }
    i += 1
  }
  None
}

///|
fn geo_region_transform_to(
  region : GeoRegion,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> GeoRegion {
  let rect = region.data_bbox
  let aspect = if rect.height == 0.0 { 1.0 } else { rect.width / rect.height }
  let target_width = if width == 0.0 { aspect * height } else { width }
  let target_height = if height == 0.0 {
    if aspect == 0.0 {
      target_width
    } else {
      target_width / aspect
    }
  } else {
    height
  }
  let sx = if rect.width == 0.0 { 1.0 } else { target_width / rect.width }
  let sy = if rect.height == 0.0 { 1.0 } else { target_height / rect.height }
  let geometries = region.geometries.map(fn(geometry) {
    match geometry {
      Polygon(polygon) =>
        Polygon({
          exterior: geo_transform_points(polygon.exterior, rect, x, y, sx, sy),
          interiors: polygon.interiors.map(fn(interior) {
            geo_transform_points(interior, rect, x, y, sx, sy)
          }),
        })
      LineString(lines) =>
        LineString({
          points: lines.points.map(fn(points) {
            geo_transform_points(points, rect, x, y, sx, sy)
          }),
        })
    }
  })
  let center = @graphic.Point::new(
    x + target_width / 2.0,
    y + target_height / 2.0,
  )
  {
    ..region,
    geometries,
    center,
    data_bbox: @graphic.BBox::new(x, y, target_width, target_height),
  }
}

///|
fn geo_transform_points(
  points : Array[@graphic.Point],
  rect : @graphic.BBox,
  x : Double,
  y : Double,
  sx : Double,
  sy : Double,
) -> Array[@graphic.Point] {
  points.map(fn(pt) {
    @graphic.Point::new(x + (pt.x - rect.x) * sx, y + (pt.y - rect.y) * sy)
  })
}

///|
fn apply_geo_name_map(
  regions : Array[GeoRegion],
  name_map : Array[@option.GeoNameMapEntry],
) -> Array[GeoRegion] {
  if name_map.length() == 0 {
    return regions
  }
  regions.map(fn(region) {
    { ..region, name: geo_name_map_alias(region.name, name_map) }
  })
}

///|
fn geo_name_map_alias(
  name : String,
  name_map : Array[@option.GeoNameMapEntry],
) -> String {
  let mut i = 0
  while i < name_map.length() {
    let entry = name_map[i]
    if entry.from_name == name {
      return entry.to_name
    }
    i += 1
  }
  name
}

///|
fn compute_geo_viewport(
  opt : @option.ChartOption,
  min_x : Double,
  max_x : Double,
  min_y : Double,
  max_y : Double,
) -> @graphic.BBox {
  let margin = 20.0
  let available_w = if opt.width > margin * 2.0 {
    opt.width - margin * 2.0
  } else {
    opt.width
  }
  let available_h = if opt.height > margin * 2.0 {
    opt.height - margin * 2.0
  } else {
    opt.height
  }
  let data_w = (max_x - min_x).abs().max(1.0e-9)
  let data_h = (max_y - min_y).abs().max(1.0e-9)
  let scale = (available_w / data_w).min(available_h / data_h)
  let fit_w = data_w * scale
  let fit_h = data_h * scale
  let x = (opt.width - fit_w) / 2.0
  let y = (opt.height - fit_h) / 2.0
  @graphic.BBox::new(x, y, fit_w, fit_h)
}

///|
fn parse_geo_json(json : Json) -> Array[GeoRegion] {
  let utf8_encoding = j_bool_opt(json, "UTF8Encoding").unwrap_or(false)
  let encode_scale = j_number_opt(json, "UTF8Scale").unwrap_or(1024.0)
  match json {
    { "features": Array(features), .. } =>
      features
      .map(fn(feature) {
        parse_geo_feature(feature, utf8_encoding, encode_scale)
      })
      .filter_map(region => region)
    _ => []
  }
}

///|
fn parse_geo_feature(
  feature : Json,
  utf8_encoding : Bool,
  encode_scale : Double,
) -> GeoRegion? {
  let properties = match j_field(feature, "properties") {
    Some(value) => value
    None => return None
  }
  let geometry = match j_field(feature, "geometry") {
    Some(value) => value
    None => return None
  }
  let geometries = parse_geo_geometry(geometry, utf8_encoding, encode_scale)
  if geometries.length() == 0 {
    return None
  }
  let name = j_string(properties, "name", "")
  let bbox = geo_geometries_bbox(geometries)
  let center = match parse_geo_cp(properties) {
    Some(cp) => cp
    None => geo_geometries_center(geometries, bbox)
  }
  Some({ name, geometries, center, data_bbox: bbox })
}

///|
fn parse_geo_geometry(
  geometry : Json,
  utf8_encoding : Bool,
  encode_scale : Double,
) -> Array[GeoGeometry] {
  match j_string(geometry, "type", "") {
    "Polygon" =>
      match j_field(geometry, "coordinates") {
        Some(Array(arr)) =>
          decode_polygon_rings(arr, geometry, utf8_encoding, encode_scale)
        _ => []
      }
    "MultiPolygon" =>
      match j_field(geometry, "coordinates") {
        Some(Array(arr)) =>
          decode_multi_polygon(arr, geometry, utf8_encoding, encode_scale)
        _ => []
      }
    "LineString" =>
      match j_field(geometry, "coordinates") {
        Some(Array(arr)) => parse_line_string_geometry(arr)
        _ => []
      }
    "MultiLineString" =>
      match j_field(geometry, "coordinates") {
        Some(Array(arr)) => parse_multi_line_string_geometry(arr)
        _ => []
      }
    _ => []
  }
}

///|
fn decode_polygon_rings(
  rings : Array[Json],
  geometry : Json,
  utf8_encoding : Bool,
  encode_scale : Double,
) -> Array[GeoGeometry] {
  if !utf8_encoding {
    return parse_polygon_rings(rings)
  }
  match j_field(geometry, "encodeOffsets") {
    Some(Array(offsets)) => decode_rings(rings, offsets, encode_scale)
    _ => parse_polygon_rings(rings)
  }
}

///|
fn decode_multi_polygon(
  polygons : Array[Json],
  geometry : Json,
  utf8_encoding : Bool,
  encode_scale : Double,
) -> Array[GeoGeometry] {
  if !utf8_encoding {
    return parse_multi_polygon(polygons)
  }
  match j_field(geometry, "encodeOffsets") {
    Some(Array(offset_groups)) => {
      let result : Array[GeoGeometry] = []
      let mut i = 0
      while i < polygons.length() {
        let polygon = polygons[i]
        let decoded = match polygon {
          Array(rings) =>
            match offset_groups.get(i) {
              Some(Array(offsets)) => decode_rings(rings, offsets, encode_scale)
              _ => parse_polygon_rings(rings)
            }
          _ => []
        }
        let mut j = 0
        while j < decoded.length() {
          result.push(decoded[j])
          j += 1
        }
        i += 1
      }
      result
    }
    _ => parse_multi_polygon(polygons)
  }
}

///|
fn decode_rings(
  rings : Array[Json],
  encode_offsets : Array[Json],
  encode_scale : Double,
) -> Array[GeoGeometry] {
  let result : Array[GeoGeometry] = []
  let mut i = 0
  while i < rings.length() {
    let ring = rings[i]
    let decoded = match ring {
      String(encoded) =>
        match encode_offsets.get(i) {
          Some(Array(offset_pair)) =>
            decode_ring(encoded, offset_pair, encode_scale)
          _ => []
        }
      _ => []
    }
    if decoded.length() > 0 {
      result.push(Polygon({ exterior: decoded, interiors: [] }))
    }
    i += 1
  }
  result
}

///|
fn decode_ring(
  coordinate : String,
  encode_offsets : Array[Json],
  encode_scale : Double,
) -> Array[@graphic.Point] {
  if encode_offsets.length() < 2 {
    return []
  }
  let result : Array[@graphic.Point] = []
  let mut prev_x = json_number_or_zero(encode_offsets[0]).to_int()
  let mut prev_y = json_number_or_zero(encode_offsets[1]).to_int()
  let mut i = 0
  while i + 1 < coordinate.length() {
    let mut x = coordinate[i].to_int() - 64
    let mut y = coordinate[i + 1].to_int() - 64
    x = (x >> 1) ^ -(x & 1)
    y = (y >> 1) ^ -(y & 1)
    x += prev_x
    y += prev_y
    prev_x = x
    prev_y = y
    result.push({
      x: x.to_double() / encode_scale,
      y: y.to_double() / encode_scale,
    })
    i += 2
  }
  result
}

///|
fn parse_polygon_rings(rings : Array[Json]) -> Array[GeoGeometry] {
  if rings.length() == 0 {
    []
  } else {
    match rings[0] {
      Array(points) => {
        let interiors : Array[Array[@graphic.Point]] = []
        let mut i = 1
        while i < rings.length() {
          match rings[i] {
            Array(interior_points) =>
              interiors.push(parse_point_array(interior_points))
            _ => ()
          }
          i += 1
        }
        [Polygon({ exterior: parse_point_array(points), interiors })]
      }
      _ => []
    }
  }
}

///|
fn parse_multi_polygon(polygons : Array[Json]) -> Array[GeoGeometry] {
  let result : Array[GeoGeometry] = []
  let mut i = 0
  while i < polygons.length() {
    match polygons[i] {
      Array(rings) => {
        let parsed = parse_polygon_rings(rings)
        let mut j = 0
        while j < parsed.length() {
          result.push(parsed[j])
          j += 1
        }
      }
      _ => ()
    }
    i += 1
  }
  result
}

///|
fn parse_line_string_geometry(coordinates : Array[Json]) -> Array[GeoGeometry] {
  [LineString({ points: [parse_point_array(coordinates)] })]
}

///|
fn parse_multi_line_string_geometry(lines : Array[Json]) -> Array[GeoGeometry] {
  let points : Array[Array[@graphic.Point]] = []
  let mut i = 0
  while i < lines.length() {
    match lines[i] {
      Array(line_points) => points.push(parse_point_array(line_points))
      _ => ()
    }
    i += 1
  }
  if points.length() == 0 {
    []
  } else {
    [LineString({ points, })]
  }
}

///|
fn parse_point_array(points : Array[Json]) -> Array[@graphic.Point] {
  let result : Array[@graphic.Point] = []
  let mut i = 0
  while i < points.length() {
    match points[i] {
      Array(pair) =>
        if pair.length() >= 2 {
          result.push(
            @graphic.Point::new(
              json_number_or_zero(pair[0]),
              json_number_or_zero(pair[1]),
            ),
          )
        }
      _ => ()
    }
    i += 1
  }
  result
}

///|
fn geo_geometries_bbox(geometries : Array[GeoGeometry]) -> @graphic.BBox {
  let mut min_x = 0.0
  let mut max_x = 0.0
  let mut min_y = 0.0
  let mut max_y = 0.0
  let mut first = true
  let mut i = 0
  while i < geometries.length() {
    match geometries[i] {
      Polygon(polygon) => {
        let points = polygon.exterior
        let mut j = 0
        while j < points.length() {
          let pt = points[j]
          if first {
            min_x = pt.x
            max_x = pt.x
            min_y = pt.y
            max_y = pt.y
            first = false
          } else {
            if pt.x < min_x {
              min_x = pt.x
            }
            if pt.x > max_x {
              max_x = pt.x
            }
            if pt.y < min_y {
              min_y = pt.y
            }
            if pt.y > max_y {
              max_y = pt.y
            }
          }
          j += 1
        }
      }
      LineString(lines) => {
        let mut j = 0
        while j < lines.points.length() {
          let points = lines.points[j]
          let mut k = 0
          while k < points.length() {
            let pt = points[k]
            if first {
              min_x = pt.x
              max_x = pt.x
              min_y = pt.y
              max_y = pt.y
              first = false
            } else {
              if pt.x < min_x {
                min_x = pt.x
              }
              if pt.x > max_x {
                max_x = pt.x
              }
              if pt.y < min_y {
                min_y = pt.y
              }
              if pt.y > max_y {
                max_y = pt.y
              }
            }
            k += 1
          }
          j += 1
        }
      }
    }
    i += 1
  }
  @graphic.BBox::new(min_x, min_y, max_x - min_x, max_y - min_y)
}

///|
fn geo_geometries_center(
  geometries : Array[GeoGeometry],
  bbox : @graphic.BBox,
) -> @graphic.Point {
  let mut largest_polygon : GeoPolygonGeometry? = None
  let mut largest_size = 0
  let mut i = 0
  while i < geometries.length() {
    match geometries[i] {
      Polygon(polygon) =>
        if polygon.exterior.length() > largest_size {
          largest_polygon = Some(polygon)
          largest_size = polygon.exterior.length()
        }
      _ => ()
    }
    i += 1
  }
  match largest_polygon {
    Some(polygon) => polygon_centroid(polygon.exterior)
    None => @graphic.Point::new(bbox.center_x(), bbox.center_y())
  }
}

///|
fn polygon_centroid(points : Array[@graphic.Point]) -> @graphic.Point {
  if points.length() == 0 {
    return @graphic.Point::new(0.0, 0.0)
  }
  let len = points.length()
  let mut signed_area = 0.0
  let mut cx = 0.0
  let mut cy = 0.0
  let mut x0 = points[len - 1].x
  let mut y0 = points[len - 1].y
  let mut i = 0
  while i < len {
    let x1 = points[i].x
    let y1 = points[i].y
    let a = x0 * y1 - x1 * y0
    signed_area += a
    cx += (x0 + x1) * a
    cy += (y0 + y1) * a
    x0 = x1
    y0 = y1
    i += 1
  }
  if signed_area != 0.0 {
    @graphic.Point::new(cx / signed_area / 3.0, cy / signed_area / 3.0)
  } else {
    @graphic.Point::new(points[0].x, points[0].y)
  }
}

///|
fn parse_geo_cp(properties : Json) -> @graphic.Point? {
  match j_field(properties, "cp") {
    Some(Array(arr)) =>
      if arr.length() >= 2 {
        Some(
          @graphic.Point::new(
            json_number_or_zero(arr[0]),
            json_number_or_zero(arr[1]),
          ),
        )
      } else {
        None
      }
    _ => None
  }
}

///|
fn json_number_or_zero(j : Json) -> Double {
  match j {
    Number(n, ..) => n
    _ => 0.0
  }
}

///|
fn j_number_opt(j : Json, key : String) -> Double? {
  match j_field(j, key) {
    Some(Number(n, ..)) => Some(n)
    _ => None
  }
}

///|
fn j_field(j : Json, key : String) -> Json? {
  match j {
    Object(map) => map.get(key)
    _ => None
  }
}

///|
fn j_string(j : Json, key : String, default_val : String) -> String {
  match j_field(j, key) {
    Some(String(s)) => s
    _ => default_val
  }
}

///|
fn j_bool_opt(j : Json, key : String) -> Bool? {
  match j_field(j, key) {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
}
