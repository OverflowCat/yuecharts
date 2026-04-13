// Tests for layout/grid.mbt
// Corresponds to: echarts/src/coord/cartesian/Grid.ts

///|
test "resolve_size Px" {
  assert_eq(resolve_size(@option.SizeSpec::Px(50.0), 400.0), 50.0)
  assert_eq(resolve_size(@option.SizeSpec::Px(0.0), 400.0), 0.0)
  assert_eq(resolve_size(@option.SizeSpec::Px(400.0), 400.0), 400.0)
}

///|
test "resolve_size Pct" {
  assert_eq(resolve_size(@option.SizeSpec::Pct(25.0), 400.0), 100.0)
  assert_eq(resolve_size(@option.SizeSpec::Pct(100.0), 200.0), 200.0)
  assert_eq(resolve_size(@option.SizeSpec::Pct(0.0), 400.0), 0.0)
  assert_eq(resolve_size(@option.SizeSpec::Pct(50.0), 800.0), 400.0)
}

///|
test "compute_grid_bbox with Px margins" {
  let grid : @option.GridOption = {
    left: "60",
    right: "20",
    top: "40",
    bottom: "60",
    width: None,
    height: None,
    contain_label: false,
  }
  let bbox = compute_grid_bbox(grid, 400.0, 300.0)
  assert_eq(bbox.x, 60.0)
  assert_eq(bbox.y, 40.0)
  assert_eq(bbox.width, 320.0) // 400 - 60 - 20
  assert_eq(bbox.height, 200.0) // 300 - 40 - 60
}

///|
test "compute_grid_bbox with Pct margins" {
  let grid : @option.GridOption = {
    left: "10%",
    right: "10%",
    top: "10%",
    bottom: "10%",
    width: None,
    height: None,
    contain_label: false,
  }
  let bbox = compute_grid_bbox(grid, 500.0, 400.0)
  assert_eq(bbox.x, 50.0)
  assert_eq(bbox.y, 40.0)
  assert_eq(bbox.width, 400.0) // 500 - 50 - 50
  assert_eq(bbox.height, 320.0) // 400 - 40 - 40
}

///|
test "compute_grid_bbox default margins" {
  let grid = @option.GridOption::default()
  let bbox = compute_grid_bbox(grid, 600.0, 400.0)
  // left=15%=90, right=10%=60, top=65px, bottom=80px
  assert_eq(bbox.x, 90.0)
  assert_eq(bbox.y, 65.0)
  assert_eq(bbox.width, 450.0) // 600 - 90 - 60
  assert_eq(bbox.height, 255.0) // 400 - 65 - 80
}

///|
test "compute_grid_bbox right and bottom" {
  let grid : @option.GridOption = {
    left: "10",
    right: "10",
    top: "10",
    bottom: "10",
    width: None,
    height: None,
    contain_label: false,
  }
  let bbox = compute_grid_bbox(grid, 200.0, 100.0)
  assert_eq(bbox.right(), 190.0)
  assert_eq(bbox.bottom(), 90.0)
}

///|
test "compute_grid_bbox honors centered top with explicit height" {
  let grid : @option.GridOption = {
    left: "15%",
    right: "10%",
    top: "center",
    bottom: "80",
    width: None,
    height: Some("230"),
    contain_label: false,
  }
  let bbox = compute_grid_bbox(grid, 800.0, 600.0)
  assert_eq(bbox.x, 120.0)
  assert_eq(bbox.y, 185.0)
  assert_eq(bbox.width, 600.0)
  assert_eq(bbox.height, 230.0)
  assert_eq(bbox.bottom(), 415.0)
}
