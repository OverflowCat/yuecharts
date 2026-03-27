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
