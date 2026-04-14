// Whitebox tests for geo coordinate parsing/building.

///|
test "geo builds viewport and regions from geojson" {
  let json_str =
    #|{
    #|  "width": 240,
    #|  "height": 180,
    #|  "geo": { "map": "demo", "aspectScale": 1, "label": { "show": true } },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Region A", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  assert_eq(geo.regions.length(), 1)
  assert_true(geo.viewport.width > 0.0)
  assert_true(geo.viewport.height > 0.0)
  let region = geo.region_by_name("Region A").unwrap()
  assert_eq(region.geometries.length(), 1)
  let center = region.screen_center(geo)
  assert_eq(center.x > 20.0, true)
  assert_eq(center.y > 20.0, true)
}

///|
test "geo honors layoutCenter and layoutSize" {
  let json_str =
    #|{
    #|  "width": 200,
    #|  "height": 150,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "layoutCenter": ["50%", "50"],
    #|    "layoutSize": 20
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Region A" },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  assert_eq(geo.viewport.x, 90.0)
  assert_eq(geo.viewport.y, 40.0)
  assert_eq(geo.viewport.width, 20.0)
  assert_eq(geo.viewport.height, 20.0)
}

///|
test "geo honors explicit box layout" {
  let json_str =
    #|{
    #|  "width": 200,
    #|  "height": 150,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "left": 10,
    #|    "right": "50%",
    #|    "top": 30,
    #|    "bottom": 40
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Region A" },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  assert_eq(geo.viewport.x, 10.0)
  assert_eq(geo.viewport.y, 30.0)
  assert_eq(geo.viewport.width, 90.0)
  assert_eq(geo.viewport.height, 80.0)
}

///|
test "exclusive map series honors box layout" {
  let json_str =
    #|{
    #|  "width": 200,
    #|  "height": 150,
    #|  "series": [{
    #|    "type": "map",
    #|    "map": "demo",
    #|    "left": 10,
    #|    "right": "50%",
    #|    "top": 30,
    #|    "bottom": 40
    #|  }],
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Region A" },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  assert_eq(geo.viewport.x, 10.0)
  assert_eq(geo.viewport.y, 30.0)
  assert_eq(geo.viewport.width, 90.0)
  assert_eq(geo.viewport.height, 80.0)
}

///|
test "geo honors center and zoom" {
  let json_str =
    #|{
    #|  "width": 100,
    #|  "height": 100,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "left": 0,
    #|    "top": 0,
    #|    "width": 100,
    #|    "height": 100,
    #|    "center": [5, 5],
    #|    "zoom": 2
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Region A" },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  let center = geo.data_to_point(5.0, 5.0)
  assert_eq(center.x, 50.0)
  assert_eq(center.y, 50.0)
  let corner = geo.data_to_point(10.0, 10.0)
  assert_eq(corner.x, 150.0)
  assert_eq(corner.y, -50.0)
  let raw = geo.point_to_data(corner)
  assert_eq(raw.x, 10.0)
  assert_eq(raw.y, 10.0)
}

///|
test "exclusive map series honors center and zoom" {
  let json_str =
    #|{
    #|  "width": 100,
    #|  "height": 100,
    #|  "series": [{
    #|    "type": "map",
    #|    "map": "demo",
    #|    "left": 0,
    #|    "top": 0,
    #|    "width": 100,
    #|    "height": 100,
    #|    "center": [5, 5],
    #|    "zoom": 2
    #|  }],
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Region A" },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  let center = geo.data_to_point(5.0, 5.0)
  assert_eq(center.x, 50.0)
  assert_eq(center.y, 50.0)
  let corner = geo.data_to_point(10.0, 10.0)
  assert_eq(corner.x, 150.0)
  assert_eq(corner.y, -50.0)
}

///|
test "geo honors boundingCoords before center and zoom" {
  let json_str =
    #|{
    #|  "width": 100,
    #|  "height": 100,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "left": 0,
    #|    "top": 0,
    #|    "width": 100,
    #|    "height": 100,
    #|    "boundingCoords": [[-10, -10], [10, 10]],
    #|    "center": [5, 5],
    #|    "zoom": 2
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Region A" },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  let center = geo.data_to_point(5.0, 5.0)
  assert_eq(center.x, 50.0)
  assert_eq(center.y, 50.0)
  let corner = geo.data_to_point(0.0, 0.0)
  assert_eq(corner.x, 0.0)
  assert_eq(corner.y, 100.0)
}

///|
test "exclusive map series honors boundingCoords before center and zoom" {
  let json_str =
    #|{
    #|  "width": 100,
    #|  "height": 100,
    #|  "series": [{
    #|    "type": "map",
    #|    "map": "demo",
    #|    "left": 0,
    #|    "top": 0,
    #|    "width": 100,
    #|    "height": 100,
    #|    "boundingCoords": [[-10, -10], [10, 10]],
    #|    "center": [5, 5],
    #|    "zoom": 2
    #|  }],
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Region A" },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  let center = geo.data_to_point(5.0, 5.0)
  assert_eq(center.x, 50.0)
  assert_eq(center.y, 50.0)
  let corner = geo.data_to_point(0.0, 0.0)
  assert_eq(corner.x, 0.0)
  assert_eq(corner.y, 100.0)
}

///|
test "geo honors nameProperty for geojson region names" {
  let json_str =
    #|{
    #|  "width": 200,
    #|  "height": 150,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1,
    #|    "nameProperty": "alias"
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "alias": "Region A", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  match geo.region_by_name("Region A") {
    Some(_) => ()
    None => assert_true(false)
  }
  match geo.region_by_name("alias") {
    Some(_) => assert_true(false)
    None => ()
  }
}

///|
test "exclusive map series honors nameProperty for geojson region names" {
  let json_str =
    #|{
    #|  "width": 200,
    #|  "height": 150,
    #|  "series": [{
    #|    "type": "map",
    #|    "map": "demo",
    #|    "nameProperty": "alias"
    #|  }],
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "alias": "Region A", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  match geo.region_by_name("Region A") {
    Some(_) => ()
    None => assert_true(false)
  }
  match geo.region_by_name("alias") {
    Some(_) => assert_true(false)
    None => ()
  }
}

///|
test "geo decodes UTF8 compressed polygon geojson" {
  let json_str =
    #|{
    #|  "width": 240,
    #|  "height": 180,
    #|  "geo": { "map": "demo", "aspectScale": 1 },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "UTF8Encoding": true,
    #|      "UTF8Scale": 1,
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Compressed", "cp": [5, 5] },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "encodeOffsets": [[0, 0]],
    #|          "coordinates": ["@@T@@TS@@S"]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  let region = geo.region_by_name("Compressed").unwrap()
  assert_eq(region.geometries.length(), 1)
  match region.geometries[0] {
    Polygon(polygon) => {
      assert_eq(polygon.exterior.length(), 5)
      assert_eq(polygon.exterior[1].x, 10.0)
      assert_eq(polygon.exterior[2].y, 10.0)
    }
    _ => assert_true(false)
  }
  assert_eq(region.data_bbox.width, 10.0)
  assert_eq(region.data_bbox.height, 10.0)
}

///|
test "geo parses multiline and computes bbox/center from line geometry" {
  let json_str =
    #|{
    #|  "width": 240,
    #|  "height": 180,
    #|  "geo": { "map": "demo", "aspectScale": 1 },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Route" },
    #|        "geometry": {
    #|          "type": "MultiLineString",
    #|          "coordinates": [
    #|            [[0, 0], [10, 0], [10, 5]],
    #|            [[2, 8], [8, 12]]
    #|          ]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  let region = geo.region_by_name("Route").unwrap()
  assert_eq(region.geometries.length(), 1)
  match region.geometries[0] {
    LineString(lines) => {
      assert_eq(lines.points.length(), 2)
      assert_eq(lines.points[0][2].x, 10.0)
      assert_eq(lines.points[1][1].y, 12.0)
    }
    _ => assert_true(false)
  }
  assert_eq(region.data_bbox.width, 10.0)
  assert_eq(region.data_bbox.height, 12.0)
  assert_eq(region.center.x, 5.0)
  assert_eq(region.center.y, 6.0)
}

///|
test "geo preserves polygon interiors" {
  let json_str =
    #|{
    #|  "width": 240,
    #|  "height": 180,
    #|  "geo": { "map": "demo", "aspectScale": 1 },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Donut" },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [
    #|            [[0,0],[10,0],[10,10],[0,10],[0,0]],
    #|            [[3,3],[3,7],[7,7],[7,3],[3,3]]
    #|          ]
    #|        }
    #|      }]
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  let region = geo.region_by_name("Donut").unwrap()
  match region.geometries[0] {
    Polygon(polygon) => {
      assert_eq(polygon.exterior.length(), 5)
      assert_eq(polygon.interiors.length(), 1)
      assert_eq(polygon.interiors[0].length(), 5)
      assert_eq(polygon.interiors[0][0].x, 3.0)
      assert_eq(polygon.interiors[0][2].y, 7.0)
    }
    _ => assert_true(false)
  }
}

///|
test "geo source manager loads resource with specialAreas and nameMap" {
  let json_str =
    #|{
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "rawInset", "cp": [25, 5] },
    #|        "geometry": { "type": "Polygon", "coordinates": [[[20,0],[30,0],[30,10],[20,10],[20,0]]] }
    #|      }]
    #|    },
    #|    "specialAreas": {
    #|      "rawInset": { "left": 4, "top": 12, "width": 4, "height": 4 }
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let manager = GeoSourceManager::from_option(opt)
  let loaded = manager
    .load("demo", [{ from_name: "rawInset", to_name: "Inset" }], "name")
    .unwrap()
  assert_eq(loaded.regions.length(), 1)
  let region = loaded.regions[0]
  assert_eq(region.name, "Inset")
  assert_eq(region.data_bbox.x, 4.0)
  assert_eq(region.data_bbox.y, 12.0)
  assert_eq(region.data_bbox.width, 4.0)
  assert_eq(region.data_bbox.height, 4.0)
  assert_eq(loaded.bounding_rect.x, 4.0)
  assert_eq(loaded.bounding_rect.y, 12.0)
}

///|
test "geo source manager get_map_for_user returns original registration" {
  let json_str =
    #|{
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": []
    #|    },
    #|    "specialAreas": {
    #|      "Inset": { "left": 4, "top": 12, "width": 4, "height": 4 }
    #|    }
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let manager = GeoSourceManager::from_option(opt)
  let map_for_user = manager.get_map_for_user("demo").unwrap()
  match map_for_user.geo_json {
    { "type": String("FeatureCollection"), .. } => assert_true(true)
    _ => assert_true(false)
  }
  assert_eq(map_for_user.special_areas.length(), 1)
  assert_eq(map_for_user.special_areas[0].name, "Inset")
}

///|
test "geo svg resource loads named region styles" {
  let json_str =
    #|{
    #|  "width": 240,
    #|  "height": 180,
    #|  "geo": {
    #|    "map": "demo",
    #|    "aspectScale": 1
    #|  },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "svg": "<svg width='100' height='100' viewBox='0 0 100 100'><g name='Alpha'><path d='M 0 0 L 10 0 L 10 10 L 0 10 Z' fill='#123456' stroke='#654321' stroke-width='2'/></g></svg>"
    #|  }]
    #|}
  let opt = @option.parse(json_str)
  let geo = Geo::build(opt).unwrap()
  assert_true(geo.is_svg())
  let region = geo.region_by_name("Alpha").unwrap()
  assert_eq(region.svg_fill(), Some("#123456"))
  assert_eq(region.svg_stroke_color(), Some("#654321"))
  assert_eq(region.svg_stroke_width(), Some(2.0))
  assert_eq(region.data_bbox.width, 10.0)
  assert_eq(region.data_bbox.height, 10.0)
}

///|
test "build_for_map_series uses independent geo with default aspectScale 0.75" {
  // When a series.map has no explicit geoIndex but there are geo components,
  // build_for_map_series should create a 0.75-aspect geo independent of the
  // geo component's 1.0-aspect geo.
  let json_str =
    #|{
    #|  "width": 220,
    #|  "height": 160,
    #|  "geo": { "map": "demo", "aspectScale": 1 },
    #|  "maps": [{
    #|    "name": "demo",
    #|    "geoJSON": {
    #|      "type": "FeatureCollection",
    #|      "features": [{
    #|        "type": "Feature",
    #|        "properties": { "name": "Donut" },
    #|        "geometry": {
    #|          "type": "Polygon",
    #|          "coordinates": [[[0,0],[10,0],[10,10],[0,10],[0,0]]]
    #|        }
    #|      }]
    #|    }
    #|  }],
    #|  "series": [{ "type": "map", "map": "demo", "data": [] }]
    #|}
  let opt = @option.parse(json_str)
  // Component geo uses aspectScale: 1 → square 128×128 viewport
  let component_geo = Geo::build(opt).unwrap()
  assert_eq(component_geo.viewport.width.round(), 128.0)
  assert_eq(component_geo.viewport.height.round(), 128.0)
  // Series-specific geo defaults to aspectScale 0.75 → 96×128 viewport
  let series = opt.series[0]
  let series_geo = Geo::build_for_map_series(opt, series).unwrap()
  assert_eq(series_geo.viewport.width.round(), 96.0)
  assert_eq(series_geo.viewport.height.round(), 128.0)
}
