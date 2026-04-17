// Corresponds to: echarts/src/core/echarts.ts (setOption processing)
// and echarts/src/util/model.ts (option normalization)

///|
/// Parse a JSON string into a ChartOption.
pub fn parse(json_str : String) -> ChartOption raise @json.ParseError {
  let j = @json.parse(json_str)
  parse_json(j)
}

///|
/// Parse an already-decoded JSON value into a ChartOption.
/// <=> echarts/src/core/echarts.ts:setOption
/// <=> echarts/src/model/OptionManager.ts
pub fn parse_json(j : Json) -> ChartOption {
  parse_chart_option(j)
}

///|
/// Apply outer interaction-envelope root fields that live alongside `option`.
/// <=> echarts/src/model/OptionManager.ts
pub fn apply_render_input_root_overrides(
  opt : ChartOption,
  root : Json,
) -> ChartOption {
  let width = j_number(root, "width", opt.width)
  let height = j_number(root, "height", opt.height)
  let map_registry = match j_field(root, "maps") {
    Some(Array(arr)) => {
      let merged : Array[MapRegistryOption] = []
      for item in opt.map_registry {
        merged.push(item)
      }
      for entry in arr {
        merged.push(parse_map_registry_option(entry))
      }
      merged
    }
    _ => opt.map_registry
  }
  { ..opt, width, height, map_registry }
}

///|
/// Apply the canonical interaction-state subset onto a parsed ChartOption.
/// <=> echarts/src/core/echarts.ts:dispatchAction
/// <=> echarts/src/legacy/dataSelectAction.ts
/// <=> echarts/src/component/visualMap/installCommon.ts
/// <=> echarts/src/model/OptionManager.ts (stateful option merge subset)
pub fn apply_interaction_option_patch_json(
  opt : ChartOption,
  patch : Json?,
) -> ChartOption {
  let next = apply_option_patch_legend_selected(opt, patch)
  let next = apply_option_patch_series_data_selected(next, patch)
  let next = apply_option_patch_geo_region_selected(next, patch)
  apply_option_patch_visual_map_selected(next, patch)
}

///|
/// <=> echarts/src/model/OptionManager.ts
fn apply_option_patch_legend_selected(
  opt : ChartOption,
  patch : Json?,
) -> ChartOption {
  let selected_json = patch
    .bind(value => j_field(value, "legend"))
    .bind(value => j_field(value, "selected"))
  match selected_json {
    Some(Object(entries)) => {
      let legend = opt.legend.unwrap_or(LegendOption::default())
      let selected = legend.selected
      for name, value in entries {
        match value {
          True => legend_selection_upsert(selected, name, true)
          False => legend_selection_upsert(selected, name, false)
          _ => ()
        }
      }
      { ..opt, legend: Some({ ..legend, selected, }) }
    }
    _ => opt
  }
}

///|
/// <=> echarts/src/model/OptionManager.ts
fn apply_option_patch_series_data_selected(
  opt : ChartOption,
  patch : Json?,
) -> ChartOption {
  let series_json = patch.bind(value => j_field(value, "series"))
  match series_json {
    Some(Array(series_arr)) => {
      let series = opt.series
      let mut si = 0
      while si < series_arr.length() && si < series.length() {
        let series_patch = series_arr[si]
        let data_json = j_field(series_patch, "data")
        match data_json {
          Some(Array(data_arr)) => {
            let series_opt = series[si]
            let data = series_opt.data
            let mut di = 0
            while di < data_arr.length() && di < data.length() {
              match j_field(data_arr[di], "selected") {
                Some(True) => data[di] = { ..data[di], selected: Some(true) }
                Some(False) => data[di] = { ..data[di], selected: Some(false) }
                _ => ()
              }
              di += 1
            }
            series[si] = { ..series_opt, data, }
          }
          _ => ()
        }
        si += 1
      }
      { ..opt, series, }
    }
    _ => opt
  }
}

///|
/// <=> echarts/src/model/OptionManager.ts
fn apply_option_patch_geo_region_selected(
  opt : ChartOption,
  patch : Json?,
) -> ChartOption {
  let geo_json = patch.bind(value => j_field(value, "geo"))
  match geo_json {
    Some(Array(geo_arr)) => {
      let geo = opt.geo
      let mut gi = 0
      while gi < geo_arr.length() && gi < geo.length() {
        let geo_patch = geo_arr[gi]
        let regions_json = j_field(geo_patch, "regions")
        match regions_json {
          Some(Array(regions_arr)) => {
            let geo_opt = geo[gi]
            let regions = geo_opt.regions
            for region_patch in regions_arr {
              let name = j_string_opt(region_patch, "name")
              let selected = j_bool_opt(region_patch, "selected")
              match (name, selected) {
                (Some(region_name), Some(is_selected)) =>
                  match interaction_geo_region_index(regions, region_name) {
                    Some(index) => {
                      let region = regions[index]
                      regions[index] = { ..region, selected: Some(is_selected) }
                    }
                    None =>
                      regions.push({
                        name: region_name,
                        label: None,
                        item_style: None,
                        selected: Some(is_selected),
                        silent: None,
                        states: GeoStatesOption::default(),
                      })
                  }
                _ => ()
              }
            }
            geo[gi] = { ..geo_opt, regions, }
          }
          _ => ()
        }
        gi += 1
      }
      { ..opt, geo, }
    }
    _ => opt
  }
}

///|
/// <=> echarts/src/model/OptionManager.ts
fn apply_option_patch_visual_map_selected(
  opt : ChartOption,
  patch : Json?,
) -> ChartOption {
  let visual_map_json = patch.bind(value => j_field(value, "visualMap"))
  match visual_map_json {
    Some(Array(vm_arr)) => {
      let visual_map = opt.visual_map
      let mut vi = 0
      while vi < vm_arr.length() && vi < visual_map.length() {
        let vm_patch = vm_arr[vi]
        let selected_json = j_field(vm_patch, "selected")
        match selected_json {
          Some(Object(selected_map)) => {
            let vm = visual_map[vi]
            let current = vm.selected
            for key, value in selected_map {
              match value {
                True => visual_map_selection_upsert(current, key, true)
                False => visual_map_selection_upsert(current, key, false)
                _ => ()
              }
            }
            visual_map[vi] = { ..vm, selected: current }
          }
          _ => ()
        }
        vi += 1
      }
      { ..opt, visual_map, }
    }
    _ => opt
  }
}

///|
/// Apply the canonical interaction-state subset onto a parsed ChartOption.
/// <=> echarts/src/core/echarts.ts:dispatchAction
/// <=> echarts/src/legacy/dataSelectAction.ts
/// <=> echarts/src/component/visualMap/installCommon.ts
pub fn apply_interaction_state_json(
  opt : ChartOption,
  state : Json?,
) -> ChartOption {
  let next = apply_interaction_legend_selected(opt, state)
  let next = apply_interaction_series_data_selected(next, state)
  let next = apply_interaction_geo_region_selected(next, state)
  apply_interaction_visual_map_selected(next, state)
}

///|
/// Apply the supported `interaction.dispatchActions` subset onto a parsed
/// ChartOption.
/// <=> echarts/src/core/echarts.ts:dispatchAction
pub fn apply_interaction_dispatch_actions_json(
  opt : ChartOption,
  actions : Json?,
) -> ChartOption {
  match actions {
    Some(Array(arr)) => {
      let mut current = opt
      for action in arr {
        current = apply_interaction_dispatch_action(current, action)
      }
      current
    }
    _ => opt
  }
}

///|
/// <=> echarts/src/core/echarts.ts:dispatchAction
fn apply_interaction_dispatch_action(
  opt : ChartOption,
  action : Json,
) -> ChartOption {
  let action_type = j_string_opt(action, "type").unwrap_or("")
  match action_type {
    "legendSelect" => apply_dispatch_action_legend_select(opt, action, true)
    "legendUnSelect" => apply_dispatch_action_legend_select(opt, action, false)
    "legendToggleSelect" => apply_dispatch_action_legend_toggle(opt, action)
    // legendAllSelect / legendInverseSelect: require iterating all known series
    // names; too complex for static renderer — recognized as no-op.
    // legendScroll: scrollable legend viewport position — no static effect.
    // Corresponds to: echarts/src/component/legend/legendAction.ts
    // Corresponds to: echarts/src/component/legend/scrollableLegendAction.ts
    "legendAllSelect" | "legendInverseSelect" | "legendScroll" => opt
    "select" => apply_dispatch_action_data_select(opt, action, "select")
    "unselect" => apply_dispatch_action_data_select(opt, action, "unselect")
    "toggleSelect" => apply_dispatch_action_data_select(opt, action, "toggle")
    // Legacy pie/map select aliases forwarded to modern select/unselect/toggle.
    // Corresponds to: echarts/src/legacy/dataSelectAction.ts
    "pieSelect" | "mapSelect" =>
      apply_dispatch_action_data_select(opt, action, "select")
    "pieUnSelect" | "mapUnSelect" =>
      apply_dispatch_action_data_select(opt, action, "unselect")
    "pieToggleSelect" | "mapToggleSelect" =>
      apply_dispatch_action_data_select(opt, action, "toggle")
    "highlight" => apply_dispatch_action_highlight(opt, action, true)
    "downplay" => apply_dispatch_action_highlight(opt, action, false)
    "treeExpandAndCollapse" =>
      apply_dispatch_action_tree_expand_and_collapse(opt, action)
    "dataZoom" => apply_dispatch_action_data_zoom(opt, action)
    "selectDataRange" => apply_dispatch_action_select_data_range(opt, action)
    // treemapRootToNode, treemapZoomToNode, treemapRender, treemapMove:
    // Viewport navigation; no static option effect — recognized but no-op.
    // Corresponds to: echarts/src/chart/treemap/treemapAction.ts
    "treemapRootToNode"
    | "treemapZoomToNode"
    | "treemapRender"
    | "treemapMove" => opt
    // sunburstRootToNode: Viewport navigation; no static option effect.
    // sunburstHighlight / sunburstUnhighlight: deprecated, forwarded to highlight/downplay upstream.
    // Corresponds to: echarts/src/chart/sunburst/sunburstAction.ts
    "sunburstRootToNode" | "sunburstHighlight" | "sunburstUnhighlight" => opt
    // treeRoam: coordinate transform only, no option change.
    // Corresponds to: echarts/src/chart/tree/treeAction.ts
    "treeRoam" => opt
    // expandAxisBreak / collapseAxisBreak / toggleAxisBreak: modify axis break
    // expanded state; requires axis model reconciliation — no-op in static renderer.
    // Corresponds to: echarts/src/component/axis/axisAction.ts
    "expandAxisBreak" | "collapseAxisBreak" | "toggleAxisBreak" => opt
    // axisAreaSelect: parallel axis interval selection (viewport-only).
    // parallelAxisExpand: parallel axis expand window (viewport-only).
    // Corresponds to: echarts/src/component/axis/parallelAxisAction.ts
    "axisAreaSelect" | "parallelAxisExpand" => opt
    // timelineChange / timelinePlayChange: timeline has no type in static renderer.
    // Corresponds to: echarts/src/component/timeline/timelineAction.ts
    "timelineChange" | "timelinePlayChange" => opt
    _ => opt
  }
}

///|
/// <=> echarts/src/component/legend/legendAction.ts
fn apply_dispatch_action_legend_select(
  opt : ChartOption,
  action : Json,
  selected : Bool,
) -> ChartOption {
  match j_string_opt(action, "name") {
    Some(name) => {
      let legend = opt.legend.unwrap_or(LegendOption::default())
      let items = legend.selected
      legend_selection_upsert(items, name, selected)
      { ..opt, legend: Some({ ..legend, selected: items }) }
    }
    None => opt
  }
}

///|
/// <=> echarts/src/component/legend/legendAction.ts
fn apply_dispatch_action_legend_toggle(
  opt : ChartOption,
  action : Json,
) -> ChartOption {
  match j_string_opt(action, "name") {
    Some(name) => {
      let legend = opt.legend.unwrap_or(LegendOption::default())
      let current = LegendOption::is_selected(legend, name)
      apply_dispatch_action_legend_select(opt, action, !current)
    }
    None => opt
  }
}

///|
/// <=> echarts/src/legacy/dataSelectAction.ts
fn apply_dispatch_action_data_select(
  opt : ChartOption,
  action : Json,
  mode : String,
) -> ChartOption {
  match resolve_interaction_series_target(opt.series, action) {
    Some((series_index, data_index, _)) => {
      let series = opt.series
      let series_opt = series[series_index]
      let data = series_opt.data
      let item = data[data_index]
      let current_selected = item.selected.unwrap_or(false)
      let next_selected = match mode {
        "select" => true
        "unselect" => false
        _ => !current_selected
      }
      data[data_index] = { ..item, selected: Some(next_selected) }
      series[series_index] = { ..series_opt, data, }
      { ..opt, series, }
    }
    None => opt
  }
}

///|
/// Mark/unmark data items as highlighted for static emphasis rendering.
/// In dynamic ECharts, highlight enters the zrender element's emphasis state.
/// In static rendering we store the flag on DataItem.highlighted for renderers.
///
/// <=> echarts/src/util/states.ts:enterEmphasis / leaveEmphasis
/// <=> echarts/src/core/echarts.ts (highlight/downplay action handler)
/// Payload fields: seriesIndex?, seriesId?, seriesName?, dataIndex?, name?
fn apply_dispatch_action_highlight(
  opt : ChartOption,
  action : Json,
  enter : Bool,
) -> ChartOption {
  match resolve_interaction_series_target(opt.series, action) {
    Some((series_index, data_index, _)) => {
      let series = opt.series
      let series_opt = series[series_index]
      let data = series_opt.data
      let item = data[data_index]
      data[data_index] = { ..item, highlighted: Some(enter) }
      series[series_index] = { ..series_opt, data, }
      { ..opt, series, }
    }
    // If only seriesIndex given (no dataIndex), mark whole series highlighted
    None =>
      match interaction_series_index(opt.series, action) {
        Some(series_index) => {
          let series = opt.series
          let series_opt = series[series_index]
          let data = series_opt.data
          let new_data : Array[DataItem] = []
          for item in data {
            new_data.push({ ..item, highlighted: Some(enter) })
          }
          series[series_index] = { ..series_opt, data: new_data }
          { ..opt, series, }
        }
        None => opt
      }
  }
}

///|
/// Toggle node expand/collapse in tree chart.
/// Upstream toggles node.isExpand; here we toggle DataItem.collapsed (inverse).
///
/// <=> echarts/src/chart/tree/treeAction.ts:installTreeAction (treeExpandAndCollapse handler)
/// Payload fields: dataIndex (required), seriesIndex?
fn apply_dispatch_action_tree_expand_and_collapse(
  opt : ChartOption,
  action : Json,
) -> ChartOption {
  match interaction_series_index(opt.series, action) {
    Some(series_index) =>
      match j_number_opt(action, "dataIndex") {
        Some(n) => {
          let series = opt.series
          let series_opt = series[series_index]
          let data = series_opt.data
          let data_index = n.to_int()
          if data_index >= 0 && data_index < data.length() {
            let item = data[data_index]
            // collapsed: None / false → expand (isExpand=true); Some(true) → collapse
            let currently_collapsed = item.collapsed.unwrap_or(false)
            data[data_index] = { ..item, collapsed: Some(!currently_collapsed) }
            series[series_index] = { ..series_opt, data, }
            { ..opt, series, }
          } else {
            opt
          }
        }
        None => opt
      }
    // If no seriesIndex, try the first tree series
    None => {
      let mut tree_idx = -1
      let mut i = 0
      while i < opt.series.length() {
        if opt.series[i].series_type == Tree {
          tree_idx = i
          break
        }
        i += 1
      }
      if tree_idx >= 0 {
        apply_dispatch_action_tree_expand_and_collapse(
          opt,
          // inject seriesIndex into action by wrapping — but action is Json, inject via override
           action,
        )
      } else {
        opt
      }
    }
  }
}

///|
/// Apply a dataZoom range action, updating the matching DataZoomOption in ChartOption.
/// Upstream iterates effectedModels via findEffectedDataZooms and sets raw range.
///
/// <=> echarts/src/component/dataZoom/dataZoomAction.ts:installDataZoomAction
/// Payload fields: dataZoomIndex?, start?, end?, startValue?, endValue?
fn apply_dispatch_action_data_zoom(
  opt : ChartOption,
  action : Json,
) -> ChartOption {
  let data_zoom = opt.data_zoom
  if data_zoom.is_empty() {
    return opt
  }
  let zoom_index = match j_number_opt(action, "dataZoomIndex") {
    Some(n) => n.to_int()
    None => 0
  }
  if zoom_index < 0 || zoom_index >= data_zoom.length() {
    return opt
  }
  let base = data_zoom[zoom_index]
  let start = match j_number_opt(action, "start") {
    Some(n) => n
    None => base.start
  }
  let end = match j_number_opt(action, "end") {
    Some(n) => n
    None => base.end
  }
  let start_value = match interaction_stringish_opt(action, "startValue") {
    Some(s) => Some(s)
    None => base.start_value
  }
  let end_value = match interaction_stringish_opt(action, "endValue") {
    Some(s) => Some(s)
    None => base.end_value
  }
  data_zoom[zoom_index] = { start, end, start_value, end_value }
  { ..opt, data_zoom, }
}

///|
/// Updates visualMap selected range or piecewise selection from a selectDataRange dispatchAction.
/// Continuous visualMap: `selected` is a number array [min, max] → updates VisualMapOption.range.
/// Piecewise visualMap: `selected` is an object { key: bool } → updates VisualMapOption.selected.
/// <=> echarts/src/component/visualMap/visualMapAction.ts:visualMapActionHander
/// <=> echarts/src/component/visualMap/ContinuousModel.ts:setSelected
/// <=> echarts/src/component/visualMap/PiecewiseModel.ts:setSelected
fn apply_dispatch_action_select_data_range(
  opt : ChartOption,
  action : Json,
) -> ChartOption {
  let visual_map = opt.visual_map
  if visual_map.is_empty() {
    return opt
  }
  let vm_index = match j_number_opt(action, "visualMapIndex") {
    Some(n) => n.to_int()
    None => 0
  }
  if vm_index < 0 || vm_index >= visual_map.length() {
    return opt
  }
  let vm = visual_map[vm_index]
  match j_field(action, "selected") {
    Some(Array(arr)) => {
      // Continuous: selected=[start, end] → range
      let range : Array[Double] = []
      for v in arr {
        match v {
          Number(n, ..) => range.push(n)
          _ => ()
        }
      }
      visual_map[vm_index] = { ..vm, range, }
      { ..opt, visual_map, }
    }
    Some(Object(map)) => {
      // Piecewise: selected={"pieceKey": bool, ...} → selected array
      let current = vm.selected
      for key, val in map {
        let is_selected = match val {
          True => true
          False => false
          _ => true
        }
        visual_map_selection_upsert(current, key, is_selected)
      }
      visual_map[vm_index] = { ..vm, selected: current }
      { ..opt, visual_map, }
    }
    _ => opt
  }
}

///|
/// <=> echarts/src/component/legend/legendAction.ts
fn apply_interaction_legend_selected(
  opt : ChartOption,
  state : Json?,
) -> ChartOption {
  let selected_json = state.bind(value => j_field(value, "legendSelected"))
  match selected_json {
    Some(Object(entries)) => {
      let legend = opt.legend.unwrap_or(LegendOption::default())
      let selected = legend.selected
      for name, value in entries {
        match value {
          True => legend_selection_upsert(selected, name, true)
          False => legend_selection_upsert(selected, name, false)
          _ => ()
        }
      }
      { ..opt, legend: Some({ ..legend, selected, }) }
    }
    _ => opt
  }
}

///|
/// <=> echarts/src/legacy/dataSelectAction.ts
fn apply_interaction_series_data_selected(
  opt : ChartOption,
  state : Json?,
) -> ChartOption {
  let selected_json = state.bind(value => j_field(value, "seriesDataSelected"))
  match selected_json {
    Some(Array(entries)) => {
      let series = opt.series
      for entry in entries {
        match resolve_interaction_series_target(series, entry) {
          Some((series_index, data_index, selected)) => {
            let series_opt = series[series_index]
            let data = series_opt.data
            data[data_index] = { ..data[data_index], selected: Some(selected) }
            series[series_index] = { ..series_opt, data, }
          }
          None => ()
        }
      }
      { ..opt, series, }
    }
    _ => opt
  }
}

///|
/// <=> echarts/src/component/geo/GeoView.ts
fn apply_interaction_geo_region_selected(
  opt : ChartOption,
  state : Json?,
) -> ChartOption {
  let selected_json = state.bind(value => j_field(value, "geoRegionSelected"))
  match selected_json {
    Some(Array(entries)) => {
      let geo = opt.geo
      for entry in entries {
        match resolve_interaction_geo_target(geo, entry) {
          Some((geo_index, region_name, selected)) => {
            let geo_opt = geo[geo_index]
            let regions = geo_opt.regions
            match interaction_geo_region_index(regions, region_name) {
              Some(index) => {
                let region = regions[index]
                regions[index] = { ..region, selected: Some(selected) }
              }
              None =>
                regions.push({
                  name: region_name,
                  label: None,
                  item_style: None,
                  selected: Some(selected),
                  silent: None,
                  states: GeoStatesOption::default(),
                })
            }
            geo[geo_index] = { ..geo_opt, regions, }
          }
          None => ()
        }
      }
      { ..opt, geo, }
    }
    _ => opt
  }
}

///|
/// <=> echarts/src/component/visualMap/visualMapAction.ts
fn apply_interaction_visual_map_selected(
  opt : ChartOption,
  state : Json?,
) -> ChartOption {
  let selected_json = state.bind(value => j_field(value, "visualMapSelected"))
  match selected_json {
    Some(Array(entries)) => {
      let visual_map = opt.visual_map
      for entry in entries {
        match resolve_interaction_visual_map_target(visual_map, entry) {
          Some((visual_map_index, key, selected)) => {
            let vm = visual_map[visual_map_index]
            let current = vm.selected
            visual_map_selection_upsert(current, key, selected)
            visual_map[visual_map_index] = { ..vm, selected: current }
          }
          None => ()
        }
      }
      { ..opt, visual_map, }
    }
    _ => opt
  }
}

///|
/// <=> echarts/src/legacy/dataSelectAction.ts
fn resolve_interaction_series_target(
  series : Array[SeriesOption],
  entry : Json,
) -> (Int, Int, Bool)? {
  match interaction_series_index(series, entry) {
    Some(series_index) =>
      match interaction_data_index(series[series_index].data, entry) {
        Some(data_index) =>
          Some(
            (
              series_index,
              data_index,
              j_bool_opt(entry, "selected").unwrap_or(true),
            ),
          )
        None => None
      }
    None => None
  }
}

///|
/// <=> echarts/src/legacy/dataSelectAction.ts
fn interaction_series_index(series : Array[SeriesOption], entry : Json) -> Int? {
  match j_number_opt(entry, "seriesIndex") {
    Some(n) => {
      let index = n.to_int()
      if index >= 0 && index < series.length() {
        Some(index)
      } else {
        None
      }
    }
    None =>
      match j_string_opt(entry, "seriesName") {
        Some(name) => {
          let mut i = 0
          while i < series.length() {
            if series[i].name == Some(name) {
              return Some(i)
            }
            i += 1
          }
          None
        }
        None => None
      }
  }
}

///|
/// <=> echarts/src/legacy/dataSelectAction.ts
fn interaction_data_index(data : Array[DataItem], entry : Json) -> Int? {
  match j_number_opt(entry, "dataIndex") {
    Some(n) => {
      let index = n.to_int()
      if index >= 0 && index < data.length() {
        Some(index)
      } else {
        None
      }
    }
    None =>
      match j_string_opt(entry, "name") {
        Some(name) => {
          let mut i = 0
          while i < data.length() {
            if data[i].name == Some(name) {
              return Some(i)
            }
            i += 1
          }
          None
        }
        None => None
      }
  }
}

///|
/// <=> echarts/src/component/geo/GeoView.ts
fn resolve_interaction_geo_target(
  geo : Array[GeoOption],
  entry : Json,
) -> (Int, String, Bool)? {
  let geo_index = match j_number_opt(entry, "geoIndex") {
    Some(n) => n.to_int()
    None => 0
  }
  if geo_index < 0 || geo_index >= geo.length() {
    return None
  }
  match j_string_opt(entry, "name") {
    Some(name) =>
      Some((geo_index, name, j_bool_opt(entry, "selected").unwrap_or(true)))
    None => None
  }
}

///|
/// <=> echarts/src/component/geo/GeoView.ts
fn interaction_geo_region_index(
  regions : Array[GeoRegionOption],
  name : String,
) -> Int? {
  let mut i = 0
  while i < regions.length() {
    if regions[i].name == name {
      return Some(i)
    }
    i += 1
  }
  None
}

///|
/// <=> echarts/src/component/visualMap/visualMapAction.ts
fn resolve_interaction_visual_map_target(
  visual_map : Array[VisualMapOption],
  entry : Json,
) -> (Int, String, Bool)? {
  let visual_map_index = match j_number_opt(entry, "visualMapIndex") {
    Some(n) => n.to_int()
    None => 0
  }
  if visual_map_index < 0 || visual_map_index >= visual_map.length() {
    return None
  }
  match interaction_stringish_opt(entry, "key") {
    Some(key) =>
      Some(
        (visual_map_index, key, j_bool_opt(entry, "selected").unwrap_or(true)),
      )
    None => None
  }
}

///|
/// <=> echarts/src/component/legend/legendAction.ts
fn legend_selection_upsert(
  selected : Array[LegendSelection],
  name : String,
  is_selected : Bool,
) -> Unit {
  let mut i = 0
  while i < selected.length() {
    if selected[i].name == name {
      selected[i] = { name, selected: is_selected }
      return
    }
    i += 1
  }
  selected.push({ name, selected: is_selected })
}

///|
/// <=> echarts/src/component/visualMap/visualMapAction.ts
fn visual_map_selection_upsert(
  selected : Array[VisualMapSelection],
  key : String,
  is_selected : Bool,
) -> Unit {
  let mut i = 0
  while i < selected.length() {
    if selected[i].key == key {
      selected[i] = { key, selected: is_selected }
      return
    }
    i += 1
  }
  selected.push({ key, selected: is_selected })
}

///|
fn interaction_stringish_opt(j : Json, key : String) -> String? {
  match j_field(j, key) {
    Some(String(s)) => Some(s)
    Some(Number(n, ..)) => Some(n.to_string())
    _ => None
  }
}

///|
fn large_bar_render_limit() -> Int {
  3000
}

///|
fn[T] array_prefix(arr : Array[T], limit : Int) -> Array[T] {
  let out : Array[T] = []
  let mut i = 0
  let max = if arr.length() < limit { arr.length() } else { limit }
  while i < max {
    out.push(arr[i])
    i += 1
  }
  out
}

///|
fn trim_large_bar_chart_option(opt : ChartOption) -> ChartOption {
  let limit = large_bar_render_limit()
  let mut needs_axis_trim = false
  for s in opt.series {
    if s.series_type == Bar && s.large && s.data.length() > limit {
      needs_axis_trim = true
    }
  }
  let x_axis = if needs_axis_trim {
    let axes : Array[AxisOption] = []
    for axis in opt.x_axis {
      if axis.data.length() > limit {
        axes.push({ ..axis, data: array_prefix(axis.data, limit) })
      } else {
        axes.push(axis)
      }
    }
    axes
  } else {
    opt.x_axis
  }
  { ..opt, x_axis, }
}

///|
fn parse_chart_option(j : Json) -> ChartOption {
  let base = ChartOption::default()
  let width = j_number(j, "width", base.width)
  let height = j_number(j, "height", base.height)
  let background_color = j_string_opt(j, "backgroundColor")
  let text_style = match
    j_parse_optional(j, "textStyle", parse_chart_text_style_option) {
    Some(style) => style
    None => ChartTextStyleOption::default()
  }
  let titles = parse_titles(j_field(j, "title"))
  let title = if titles.is_empty() { None } else { Some(titles[0]) }
  let legend = j_parse_optional(j, "legend", parse_legend)
  let aria = j_parse_optional(j, "aria", parse_aria_option)
  let x_axis = j_parse_one_or_many(j, "xAxis", parse_axis_option_x, [
    AxisOption::default_x(),
  ])
  let y_axis = j_parse_one_or_many(j, "yAxis", parse_axis_option_y, [
    AxisOption::default_y(),
  ])
  let angle_axis = j_parse_one_or_many(
    j,
    "angleAxis",
    parse_angle_axis_option,
    [],
  )
  let radius_axis = j_parse_one_or_many(
    j,
    "radiusAxis",
    parse_radius_axis_option,
    [],
  )
  let grid = j_parse_one_or_many(j, "grid", parse_grid_option, [
    GridOption::default(),
  ])
  let polar = j_parse_one_or_many(j, "polar", parse_polar_option, [])
  let parallel = j_parse_one_or_many(j, "parallel", parse_parallel_option, [])
  let parallel_axis = j_parse_one_or_many(
    j,
    "parallelAxis",
    parse_parallel_axis_option,
    [],
  )
  let geo = j_parse_one_or_many(j, "geo", parse_geo_option, [])
  let calendar = j_parse_one_or_many(j, "calendar", parse_calendar_option, [])
  let matrix = j_parse_one_or_many(j, "matrix", parse_matrix_option, [])
  let radar = j_parse_one_or_many(j, "radar", parse_radar_option, [])
  let single_axis = j_parse_one_or_many(
    j,
    "singleAxis",
    parse_single_axis_option,
    [],
  )
  let dataset_tables = parse_dataset_tables(j)
  let series = parse_series_options_with_dataset(j, dataset_tables)
  let map_registry = j_parse_one_or_many(j, "maps", parse_map_registry_option, [])
  let visual_map = j_parse_one_or_many(j, "visualMap", parse_visual_map, [])
  let data_zoom = j_parse_one_or_many(j, "dataZoom", parse_data_zoom_option, [])
  trim_large_bar_chart_option({
    width,
    height,
    text_style,
    title,
    titles,
    legend,
    x_axis,
    y_axis,
    angle_axis,
    radius_axis,
    grid,
    polar,
    parallel,
    parallel_axis,
    geo,
    calendar,
    matrix,
    radar,
    single_axis,
    series,
    map_registry,
    background_color,
    aria,
    visual_map,
    data_zoom,
  })
}

///|
fn parse_titles(j : Json?) -> Array[TitleOption] {
  match j {
    Some(Array(arr)) => {
      let out : Array[TitleOption] = []
      for item in arr {
        match item {
          Object(_) => out.push(parse_title(item))
          _ => ()
        }
      }
      out
    }
    Some(one) =>
      match one {
        Object(_) => [parse_title(one)]
        _ => []
      }
    _ => []
  }
}

///|
/// <=> echarts/src/component/dataset/install.ts
/// <=> echarts/src/component/transform/install.ts
/// Parsed in parser fallback only; this does not implement the full component
/// lifecycle, but lets `dataset + filter transform + datasetIndex` feed series.
priv struct DatasetTable {
  dimensions : Array[String]
  rows : Array[Array[Json]]
}

///|
/// <=> echarts/src/component/dataset/install.ts
fn parse_series_options_with_dataset(
  j : Json,
  dataset_tables : Array[DatasetTable],
) -> Array[SeriesOption] {
  let mut series_json_arr : Array[Json] = []
  match j_field(j, "series") {
    Some(Array(arr)) => series_json_arr = arr
    Some(one) => series_json_arr = [one]
    None => ()
  }
  let series : Array[SeriesOption] = []
  for i, _ in series_json_arr {
    let series_j = series_json_arr[i]
    let parsed = parse_series_option(series_j)
    let dataset_index = j_int(series_j, "datasetIndex", 0)
    let patched = if parsed.data.length() == 0 &&
      dataset_index >= 0 &&
      dataset_index < dataset_tables.length() {
      match parsed.series_type {
        Pie => {
          let data = dataset_table_to_pie_data(
            dataset_tables[dataset_index],
            series_j,
          )
          { ..parsed, data, }
        }
        _ => parsed
      }
    } else {
      parsed
    }
    series.push(patched)
  }
  series
}

///|
/// <=> echarts/src/component/dataset/install.ts
/// <=> echarts/src/data/Source.ts
fn parse_dataset_tables(j : Json) -> Array[DatasetTable] {
  let tables : Array[DatasetTable] = []
  match j_field(j, "dataset") {
    Some(Array(dataset_arr)) =>
      for i, _ in dataset_arr {
        let dataset = dataset_arr[i]
        match parse_dataset_source_table(dataset) {
          Some(table) => tables.push(table)
          None =>
            match parse_dataset_filter_transform_table(dataset, tables) {
              Some(table) => tables.push(table)
              None => tables.push({ dimensions: [], rows: [] })
            }
        }
      }
    Some(one) =>
      match parse_dataset_source_table(one) {
        Some(table) => tables.push(table)
        None =>
          match parse_dataset_filter_transform_table(one, tables) {
            Some(table) => tables.push(table)
            None => ()
          }
      }
    None => ()
  }
  tables
}

///|
/// <=> echarts/src/data/Source.ts
fn parse_dataset_source_table(dataset : Json) -> DatasetTable? {
  match j_field(dataset, "source") {
    Some(Array(source_rows)) =>
      Some(dataset_table_from_source_rows(source_rows))
    _ => None
  }
}

///|
/// <=> echarts/src/component/transform/filterTransform.ts
fn parse_dataset_filter_transform_table(
  dataset : Json,
  tables : Array[DatasetTable],
) -> DatasetTable? {
  let transform = j_field(dataset, "transform")
  match transform {
    Some(transform_json) => {
      if j_string(transform_json, "type", "") != "filter" {
        return None
      }
      let source_idx = j_int(dataset, "fromDatasetIndex", 0)
      if source_idx < 0 || source_idx >= tables.length() {
        return None
      }
      let source_table = tables[source_idx]
      let config = j_field(transform_json, "config")
      let dim_idx = match config {
        Some(cfg) =>
          parse_dataset_filter_dimension(cfg, source_table.dimensions)
        None => None
      }
      let filter_value = config.bind(cfg => j_field(cfg, "value"))
      match (dim_idx, filter_value) {
        (Some(idx), Some(target)) => {
          let rows : Array[Array[Json]] = []
          for row in source_table.rows {
            if idx < row.length() &&
              dataset_filter_value_match(row[idx], target) {
              rows.push(row)
            }
          }
          Some({ dimensions: source_table.dimensions, rows })
        }
        _ => Some(source_table)
      }
    }
    None => None
  }
}

///|
/// <=> echarts/src/component/transform/filterTransform.ts
fn parse_dataset_filter_dimension(
  cfg : Json,
  dimensions : Array[String],
) -> Int? {
  match j_field(cfg, "dimension") {
    Some(Number(n, ..)) => {
      let idx = n.to_int()
      if idx >= 0 && idx.to_double() == n {
        Some(idx)
      } else {
        None
      }
    }
    Some(String(name)) => dataset_dimension_index(dimensions, name)
    _ => None
  }
}

///|
/// <=> echarts/src/component/transform/filterTransform.ts
fn dataset_filter_value_match(cell : Json, target : Json) -> Bool {
  match (cell, target) {
    (Number(a, ..), Number(b, ..)) => a == b
    (String(a), String(b)) => a == b
    (True, True) => true
    (False, False) => true
    (Null, Null) => true
    (String(a), Number(b, ..)) => {
      let parsed = try? @string.parse_double(a)
      parsed.map(v => v == b).unwrap_or(false)
    }
    (Number(a, ..), String(b)) => {
      let parsed = try? @string.parse_double(b)
      parsed.map(v => v == a).unwrap_or(false)
    }
    _ => false
  }
}

///|
/// <=> echarts/src/data/helper/sourceHelper.ts
fn dataset_table_from_source_rows(source_rows : Array[Json]) -> DatasetTable {
  let mut dimensions : Array[String] = []
  let rows : Array[Array[Json]] = []
  let mut start_idx = 0
  if source_rows.is_empty() {
    return { dimensions, rows }
  }
  match source_rows[0] {
    Array(header_or_row) =>
      if dataset_row_all_strings(header_or_row) {
        for i, _ in header_or_row {
          match header_or_row[i] {
            String(s) => dimensions.push(s)
            _ => dimensions.push("dim\{i}")
          }
        }
        start_idx = 1
      } else {
        dimensions = dataset_default_dimensions(header_or_row.length())
      }
    _ => return { dimensions, rows }
  }
  let mut i = start_idx
  while i < source_rows.length() {
    match source_rows[i] {
      Array(row) => rows.push(row)
      _ => ()
    }
    i += 1
  }
  if dimensions.is_empty() && !rows.is_empty() {
    dimensions = dataset_default_dimensions(rows[0].length())
  }
  { dimensions, rows }
}

///|
/// <=> echarts/src/data/helper/sourceHelper.ts
fn dataset_row_all_strings(row : Array[Json]) -> Bool {
  for i, _ in row {
    if !(row[i] is String(_)) {
      return false
    }
  }
  true
}

///|
/// <=> echarts/src/data/helper/sourceHelper.ts
fn dataset_default_dimensions(count : Int) -> Array[String] {
  let dims : Array[String] = []
  let mut i = 0
  while i < count {
    dims.push("dim\{i}")
    i += 1
  }
  dims
}

///|
/// <=> echarts/src/chart/pie/PieSeries.ts
/// Static subset: convert bound dataset rows into pie data items.
fn dataset_table_to_pie_data(
  table : DatasetTable,
  series_j : Json,
) -> Array[DataItem] {
  if table.rows.is_empty() {
    return []
  }
  let name_dim_idx = dataset_resolve_encode_dimension(
    series_j,
    table.dimensions,
    "itemName",
    0,
  )
  let value_dim_idx = dataset_resolve_encode_value_dimension(
    series_j,
    table.dimensions,
    table.rows,
  )
  let data : Array[DataItem] = []
  for i, _ in table.rows {
    let row = table.rows[i]
    if value_dim_idx < 0 || value_dim_idx >= row.length() {
      continue
    }
    let name = if name_dim_idx >= 0 && name_dim_idx < row.length() {
      Some(dataset_cell_to_string(row[name_dim_idx]))
    } else {
      None
    }
    let value = dataset_cell_to_number(row[value_dim_idx])
    data.push(make_data_item_num_name(value, name))
  }
  data
}

///|
/// <=> echarts/src/chart/pie/PieSeries.ts
fn dataset_resolve_encode_value_dimension(
  series_j : Json,
  dimensions : Array[String],
  rows : Array[Array[Json]],
) -> Int {
  let explicit = dataset_resolve_encode_dimension_opt(
    series_j, dimensions, "value",
  )
  match explicit {
    Some(idx) => idx
    None => {
      if rows.is_empty() {
        return 0
      }
      let row = rows[0]
      let mut i = if row.length() > 1 { 1 } else { 0 }
      while i < row.length() {
        if dataset_cell_is_numeric(row[i]) {
          return i
        }
        i += 1
      }
      0
    }
  }
}

///|
/// <=> echarts/src/chart/pie/PieSeries.ts
fn dataset_resolve_encode_dimension(
  series_j : Json,
  dimensions : Array[String],
  key : String,
  fallback : Int,
) -> Int {
  match dataset_resolve_encode_dimension_opt(series_j, dimensions, key) {
    Some(idx) => idx
    None => fallback
  }
}

///|
/// <=> echarts/src/util/types.ts (encode dimension resolving)
fn dataset_resolve_encode_dimension_opt(
  series_j : Json,
  dimensions : Array[String],
  key : String,
) -> Int? {
  let encode = j_field(series_j, "encode")
  match encode {
    Some(encode_obj) => {
      let encoded = j_field(encode_obj, key)
      match encoded {
        Some(spec) => dataset_encode_spec_to_dimension_index(spec, dimensions)
        None => None
      }
    }
    None => None
  }
}

///|
/// <=> echarts/src/util/types.ts (dimension loose spec)
fn dataset_encode_spec_to_dimension_index(
  spec : Json,
  dimensions : Array[String],
) -> Int? {
  match spec {
    Number(n, ..) => {
      let idx = n.to_int()
      if idx >= 0 && idx.to_double() == n {
        Some(idx)
      } else {
        None
      }
    }
    String(name) => dataset_dimension_index(dimensions, name)
    Array(arr) =>
      if arr.is_empty() {
        None
      } else {
        dataset_encode_spec_to_dimension_index(arr[0], dimensions)
      }
    _ => None
  }
}

///|
/// <=> echarts/src/data/helper/sourceHelper.ts
fn dataset_dimension_index(dimensions : Array[String], name : String) -> Int? {
  for i, _ in dimensions {
    if dimensions[i] == name {
      return Some(i)
    }
  }
  None
}

///|
fn dataset_cell_is_numeric(cell : Json) -> Bool {
  match cell {
    Number(_, ..) => true
    String(s) => {
      let parsed = try? @string.parse_double(s)
      parsed is Ok(_)
    }
    _ => false
  }
}

///|
fn dataset_cell_to_number(cell : Json) -> Double {
  match cell {
    Number(n, ..) => n
    String(s) => {
      let parsed = try? @string.parse_double(s)
      match parsed {
        Ok(v) => v
        Err(_) => 0.0
      }
    }
    True => 1.0
    False => 0.0
    _ => 0.0
  }
}

///|
fn dataset_cell_to_string(cell : Json) -> String {
  match cell {
    String(s) => s
    Number(n, ..) =>
      if n.to_int().to_double() == n {
        n.to_int().to_string()
      } else {
        n.to_string()
      }
    True => "true"
    False => "false"
    Null => ""
    _ => ""
  }
}

///|
fn make_data_item_num_name(value : Double, name : String?) -> DataItem {
  {
    value: DataValue::Num(value),
    raw_value_parts: None,
    raw_item: None,
    id: None,
    name,
    depth: None,
    source: None,
    target: None,
    symbol: None,
    coords: None,
    from_name: None,
    to_name: None,
    cursor: None,
    selected: None,
    silent: None,
    label: None,
    item_style: None,
    states: GeoStatesOption::default(),
    children: [],
    collapsed: None,
    title_offset_center: None,
    detail_offset_center: None,
    highlighted: None,
  }
}

///|
fn parse_chart_text_style_option(j : Json) -> ChartTextStyleOption {
  {
    color: j_string_opt(j, "color"),
    font_size: j_number_opt(j, "fontSize"),
    font_family: j_string_opt(j, "fontFamily"),
    font_weight: j_string_opt(j, "fontWeight"),
  }
}

///|
fn parse_title(j : Json) -> TitleOption {
  let base = TitleOption::default()
  {
    text: j_string(j, "text", base.text),
    subtext: j_string(j, "subtext", base.subtext),
    left: j_string_or_number(j, "left", base.left),
    top: j_string_or_number(j, "top", base.top),
    text_align: j_string_opt(j, "textAlign"),
    text_style: parse_title_text_style_option(
      j_field_or_self(j, "textStyle"),
      base.text_style,
    ),
    subtext_style: parse_title_text_style_option(
      j_field_or_self(j, "subtextStyle"),
      base.subtext_style,
    ),
  }
}

///|
fn parse_title_text_style_option(
  j : Json,
  base : TitleTextStyleOption,
) -> TitleTextStyleOption {
  {
    color: j_string(j, "color", base.color),
    font_size: j_number(j, "fontSize", base.font_size),
    font_weight: j_string(j, "fontWeight", base.font_weight),
    font_family: j_string(j, "fontFamily", base.font_family),
  }
}

///|
fn parse_legend(j : Json) -> LegendOption {
  let base = LegendOption::default()
  {
    show: j_bool(j, "show", base.show),
    left: j_string_or_number(j, "left", base.left),
    top: j_string_or_number(j, "top", base.top),
    bottom: j_string_or_number(j, "bottom", base.bottom),
    orient: j_string(j, "orient", base.orient),
    data: j_string_array_lossy(j, "data", base.data),
    selected: parse_legend_selected(j),
  }
}

///|
fn parse_legend_selected(j : Json) -> Array[LegendSelection] {
  match j_field(j, "selected") {
    Some(Object(map)) => {
      let items : Array[LegendSelection] = []
      for name, value in map {
        let selected = match value {
          True => true
          False => false
          _ => true
        }
        items.push({ name, selected })
      }
      items
    }
    _ => []
  }
}

///|
/// Parse the `breaks` array on an axis option.
/// Corresponds to: echarts/src/scale/breakImpl.ts parseAxisBreakOption
fn parse_axis_breaks(j : Json) -> Array[AxisBreakOption] {
  match j_field(j, "breaks") {
    Some(Array(arr)) => {
      let out : Array[AxisBreakOption] = []
      for item in arr {
        match item {
          Object(_) => {
            let start = j_number(item, "start", 0.0)
            let end = j_number(item, "end", 0.0)
            // gap may be a percent string "1.5%" or a number
            let gap = match j_field(item, "gap") {
              Some(String(s)) => s
              Some(Number(n, ..)) => n.to_string()
              _ => "1.5%"
            }
            // Skip expanded breaks (interactive-only; not relevant for static render)
            let is_expanded = j_bool(item, "isExpanded", false)
            if !is_expanded && start < end {
              out.push({ start, end, gap })
            }
          }
          _ => ()
        }
      }
      out
    }
    _ => []
  }
}

///|
/// Parse the `breakArea` option for axis break visual style.
/// Corresponds to: echarts/src/coord/axisCommonTypes.ts BreakAreaOption
fn parse_break_area_option(j : Json) -> BreakAreaOption {
  let base = BreakAreaOption::default()
  let zigzag_amplitude = j_number(j, "zigzagAmplitude", base.zigzag_amplitude)
  let zigzag_min_span = j_number(j, "zigzagMinSpan", base.zigzag_min_span)
  let zigzag_max_span = j_number(j, "zigzagMaxSpan", base.zigzag_max_span)
  let zigzag_z = j_number_opt(j, "zigzagZ")
  let item_style = j_field(j, "itemStyle")
  let opacity = match item_style {
    Some(js) => j_number(js, "opacity", base.opacity)
    None => base.opacity
  }
  let color = match item_style {
    Some(js) => j_string_opt(js, "color")
    None => None
  }
  {
    zigzag_amplitude,
    zigzag_min_span,
    zigzag_max_span,
    zigzag_z,
    color,
    opacity,
  }
}

///|
fn parse_axis_option_x(j : Json) -> AxisOption {
  let axis = parse_axis_option(j, AxisOption::default_x())
  // Scatter examples such as Anscombe's quartet omit `type` on xAxis but
  // still expect a numeric axis. ECharts treats an untyped, data-less xAxis as
  // value-like in this case, so mirror that static inference here.
  if j_field(j, "type") is None && axis.data.length() == 0 {
    { ..axis, axis_type: AxisType::Value }
  } else {
    axis
  }
}

///|
fn parse_axis_option_y(j : Json) -> AxisOption {
  parse_axis_option(j, AxisOption::default_y())
}

///|
fn parse_angle_axis_option(j : Json) -> AxisOption {
  let base = {
    ..AxisOption::default_y(),
    start_angle: Some(90.0),
    clockwise: Some(true),
  }
  parse_axis_option(j, base)
}

///|
fn parse_radius_axis_option(j : Json) -> AxisOption {
  parse_axis_option(j, AxisOption::default_y())
}

///|
fn parse_axis_option(j : Json, base : AxisOption) -> AxisOption {
  let type_field = j_field(j, "type")
  let position = match j_string(j, "position", "") {
    "bottom" => Some(AxisPosition::Bottom)
    "top" => Some(AxisPosition::Top)
    "left" => Some(AxisPosition::Left)
    "right" => Some(AxisPosition::Right)
    _ => base.position
  }
  let data = j_string_array_lossy(j, "data", base.data)
  let axis_type = match type_field {
    Some(String(type_str)) =>
      match type_str {
        "value" => AxisType::Value
        "category" => AxisType::Category
        "time" => AxisType::Time
        "log" => AxisType::Log
        _ => base.axis_type
      }
    _ => if data.length() > 0 { AxisType::Category } else { base.axis_type }
  }
  let name = j_string_opt(j, "name")
  let min = j_number_opt(j, "min")
  let max = j_number_opt(j, "max")
  // "scale": true means axis does not force-include 0 (fits to data range)
  let scale = j_bool(j, "scale", base.scale)
  let grid_index = Some(j_int(j, "gridIndex", base.grid_index.unwrap_or(0)))
  let polar_index = Some(j_int(j, "polarIndex", base.polar_index.unwrap_or(0)))
  let start_angle = match j_field(j, "startAngle") {
    Some(Number(n, ..)) => Some(n)
    _ => base.start_angle
  }
  let end_angle = match j_field(j, "endAngle") {
    Some(Number(n, ..)) => Some(n)
    _ => base.end_angle
  }
  let clockwise = match j_field(j, "clockwise") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => base.clockwise
  }
  let inverse = j_bool(j, "inverse", base.inverse)
  // echarts/src/coord/axisHelper.ts:makeLabelFormatter - string template {value}
  let label_formatter = match j_field(j, "axisLabel") {
    Some(label_obj) => j_string_opt(label_obj, "formatter")
    None => None
  }
  // echarts/src/util/types.ts AxisBreakOption — parse the breaks array
  let breaks = parse_axis_breaks(j)
  // echarts/src/coord/axisCommonTypes.ts BreakAreaOption
  let break_area = j_parse_optional(j, "breakArea", parse_break_area_option)
  {
    axis_type,
    position,
    name,
    data,
    min,
    max,
    scale,
    grid_index,
    polar_index,
    start_angle,
    end_angle,
    clockwise,
    inverse,
    label_formatter,
    breaks,
    break_area,
  }
}

///|
fn parse_grid_option(j : Json) -> GridOption {
  let base = GridOption::default()
  {
    left: j_string_or_number_as_string_opt(j, "left", Some(base.left)).unwrap_or(
      base.left,
    ),
    right: j_string_or_number_as_string_opt(j, "right", Some(base.right)).unwrap_or(
      base.right,
    ),
    top: j_string_or_number_as_string_opt(j, "top", Some(base.top)).unwrap_or(
      base.top,
    ),
    bottom: j_string_or_number_as_string_opt(j, "bottom", Some(base.bottom)).unwrap_or(
      base.bottom,
    ),
    width: j_string_or_number_as_string_opt(j, "width", base.width),
    height: j_string_or_number_as_string_opt(j, "height", base.height),
    contain_label: j_bool(j, "containLabel", base.contain_label),
  }
}

///|
fn parse_polar_option(j : Json) -> PolarOption {
  let base = PolarOption::default()
  let center = j_stringish_array(j, "center", base.center)
  let radius = match j_field(j, "radius") {
    Some(Array(arr)) => arr.map(json_to_stringish_zero)
    Some(String(s)) => ["0", s]
    Some(Number(n, ..)) => ["0", "\{n}"]
    _ => base.radius
  }
  { center, radius }
}

///|
fn parse_geo_option(j : Json) -> GeoOption {
  let base = GeoOption::default()
  {
    map: j_string(j, "map", base.map),
    center: match j_field(j, "center") {
      Some(Array(arr)) => Some(arr.map(json_to_stringish_zero))
      Some(String(s)) => Some([s])
      _ => base.center
    },
    zoom: j_number(j, "zoom", base.zoom),
    left: j_string_or_number_as_string_opt(j, "left", base.left),
    top: j_string_or_number_as_string_opt(j, "top", base.top),
    right: j_string_or_number_as_string_opt(j, "right", base.right),
    bottom: j_string_or_number_as_string_opt(j, "bottom", base.bottom),
    width: j_string_or_number_as_string_opt(j, "width", base.width),
    height: j_string_or_number_as_string_opt(j, "height", base.height),
    layout_center: match j_field(j, "layoutCenter") {
      Some(_) => Some(j_stringish_array(j, "layoutCenter", []))
      None => base.layout_center
    },
    layout_size: j_string_or_number_as_string_opt(
      j,
      "layoutSize",
      base.layout_size,
    ),
    bounding_coords: match j_field(j, "boundingCoords") {
      Some(Array(arr)) => pair_number_arrays_from_json(arr)
      _ => base.bounding_coords
    },
    roam: j_bool(j, "roam", base.roam),
    aspect_scale: j_number_opt(j, "aspectScale"),
    name_property: match j_string_opt(j, "nameProperty") {
      Some(value) => Some(value)
      None => base.name_property
    },
    silent: j_bool(j, "silent", base.silent),
    label: parse_geo_label_option(j_field_or_self(j, "label")),
    item_style: parse_geo_item_style_option(j_field_or_self(j, "itemStyle")),
    states: parse_geo_states_option(j),
    name_map: parse_geo_name_map(j),
    regions: j_parse_array(j, "regions", parse_geo_region_option, []),
  }
}

///|
fn parse_parallel_option(j : Json) -> ParallelOption {
  let base = ParallelOption::default()
  {
    left: parse_size_spec(j, "left", base.left),
    right: parse_size_spec(j, "right", base.right),
    top: parse_size_spec(j, "top", base.top),
    bottom: parse_size_spec(j, "bottom", base.bottom),
    layout: j_string(j, "layout", base.layout),
    axis_expandable: j_bool(j, "axisExpandable", base.axis_expandable),
    axis_expand_center: match j_field(j, "axisExpandCenter") {
      Some(Number(n, ..)) => Some(n.to_int())
      _ => base.axis_expand_center
    },
    axis_expand_count: j_int(j, "axisExpandCount", base.axis_expand_count),
    axis_expand_width: j_number(j, "axisExpandWidth", base.axis_expand_width),
  }
}

///|
fn parse_parallel_axis_option(j : Json) -> ParallelAxisOption {
  let base = ParallelAxisOption::default()
  {
    axis_type: match j_string(j, "type", "") {
      "category" => AxisType::Category
      "time" => AxisType::Time
      "log" => AxisType::Log
      "value" => AxisType::Value
      _ => base.axis_type
    },
    dim: j_int(j, "dim", base.dim),
    parallel_index: j_int(j, "parallelIndex", base.parallel_index),
    name: j_string_opt(j, "name"),
    data: j_string_array_lossy(j, "data", base.data),
    min: j_number_opt(j, "min"),
    max: j_number_opt(j, "max"),
    inverse: j_bool(j, "inverse", base.inverse),
    show: j_bool(j, "show", base.show),
  }
}

///|
fn parse_single_axis_option(j : Json) -> SingleAxisOption {
  let base = SingleAxisOption::default()
  {
    axis_type: match j_string(j, "type", "") {
      "category" => AxisType::Category
      "time" => AxisType::Time
      "log" => AxisType::Log
      "value" => AxisType::Value
      _ => base.axis_type
    },
    orient: j_string(j, "orient", base.orient),
    position: j_string(j, "position", base.position),
    left: parse_size_spec_opt(j, "left", base.left),
    top: parse_size_spec_opt(j, "top", base.top),
    right: parse_size_spec_opt(j, "right", base.right),
    bottom: parse_size_spec_opt(j, "bottom", base.bottom),
    width: parse_size_spec_opt(j, "width", base.width),
    height: parse_size_spec_opt(j, "height", base.height),
    min: j_number_opt(j, "min"),
    max: j_number_opt(j, "max"),
    data: j_string_array_lossy(j, "data", base.data),
    inverse: j_bool(j, "inverse", base.inverse),
    axis_line: parse_single_axis_line_option(j),
    axis_tick: parse_single_axis_tick_option(j),
    axis_label: parse_single_axis_label_option(j),
    split_line: parse_single_axis_split_line_option(j),
  }
}

///|
fn parse_single_axis_line_option(j : Json) -> SingleAxisLineOption {
  let base = SingleAxisLineOption::default()
  match j_field(j, "axisLine") {
    Some(value) => {
      let line_style = match j_field(value, "lineStyle") {
        Some(style) => {
          let line_style_base = SingleAxisLineStyleOption::default()
          {
            width: j_number(style, "width", line_style_base.width),
            line_type: j_string(style, "type", line_style_base.line_type),
          }
        }
        None => base.line_style
      }
      { show: j_bool(value, "show", base.show), line_style }
    }
    None => base
  }
}

///|
fn parse_single_axis_tick_option(j : Json) -> SingleAxisTickOption {
  let base = SingleAxisTickOption::default()
  match j_field(j, "axisTick") {
    Some(value) => {
      let width = match j_field(value, "lineStyle") {
        Some(style) => j_number(style, "width", base.width)
        None => base.width
      }
      {
        show: j_bool(value, "show", base.show),
        length: j_number(value, "length", base.length),
        width,
        inside: j_bool(value, "inside", base.inside),
      }
    }
    None => base
  }
}

///|
fn parse_single_axis_label_option(j : Json) -> SingleAxisLabelOption {
  let base = SingleAxisLabelOption::default()
  match j_field(j, "axisLabel") {
    Some(value) =>
      {
        show: j_bool(value, "show", base.show),
        inside: j_bool(value, "inside", base.inside),
        rotate: j_number(value, "rotate", base.rotate),
      }
    None => base
  }
}

///|
fn parse_single_axis_split_line_option(j : Json) -> SingleAxisSplitLineOption {
  let base = SingleAxisSplitLineOption::default()
  match j_field(j, "splitLine") {
    Some(value) => {
      let line_style = j_field(value, "lineStyle")
      {
        show: j_bool(value, "show", base.show),
        line_type: match line_style {
          Some(style) => j_string(style, "type", base.line_type)
          None => base.line_type
        },
        opacity: match line_style {
          Some(style) => j_number(style, "opacity", base.opacity)
          None => base.opacity
        },
      }
    }
    None => base
  }
}

///|
fn parse_geo_item_style_option(j : Json) -> GeoItemStyleOption {
  let base = GeoItemStyleOption::default()
  {
    area_color: j_string_opt(j, "areaColor"),
    border_color: j_string(j, "borderColor", base.border_color),
    border_width: j_number(j, "borderWidth", base.border_width),
  }
}

///|
fn parse_geo_item_style_patch_option(j : Json) -> GeoItemStylePatchOption {
  {
    color: j_string_opt(j, "color"),
    area_color: j_string_opt(j, "areaColor"),
    border_color: j_string_opt(j, "borderColor"),
    border_width: j_number_opt(j, "borderWidth"),
    opacity: j_number_opt(j, "opacity"),
    border_radius: match j_field(j, "borderRadius") {
      Some(Number(n, ..)) => Some([n])
      Some(Array(arr)) => {
        let vals = arr.filter_map(fn(v) {
          match v {
            Number(n, ..) => Some(n)
            _ => None
          }
        })
        if vals.length() > 0 {
          Some(vals)
        } else {
          None
        }
      }
      _ => None
    },
  }
}

///|
fn parse_geo_state_option(j : Json) -> GeoStateOption {
  {
    item_style: match j_field(j, "itemStyle") {
      Some(value) => Some(parse_geo_item_style_patch_option(value))
      None => None
    },
    label: match j_field(j, "label") {
      Some(value) => Some(parse_geo_label_patch_option(value))
      None => None
    },
  }
}

///|
fn parse_geo_states_option(j : Json) -> GeoStatesOption {
  {
    emphasis: match j_field(j, "emphasis") {
      Some(value) => Some(parse_geo_state_option(value))
      None => None
    },
    select: match j_field(j, "select") {
      Some(value) => Some(parse_geo_state_option(value))
      None => None
    },
    blur: match j_field(j, "blur") {
      Some(value) => Some(parse_geo_state_option(value))
      None => None
    },
  }
}

///|
fn parse_geo_region_option(j : Json) -> GeoRegionOption {
  {
    name: j_string(j, "name", ""),
    label: match j_field(j, "label") {
      Some(value) => Some(parse_geo_label_patch_option(value))
      None => None
    },
    item_style: match j_field(j, "itemStyle") {
      Some(value) => Some(parse_geo_item_style_patch_option(value))
      None => None
    },
    selected: match j_field(j, "selected") {
      Some(True) => Some(true)
      Some(False) => Some(false)
      _ => None
    },
    silent: match j_field(j, "silent") {
      Some(True) => Some(true)
      Some(False) => Some(false)
      _ => None
    },
    states: parse_geo_states_option(j),
  }
}

///|
fn parse_geo_name_map(j : Json) -> Array[GeoNameMapEntry] {
  match j_field(j, "nameMap") {
    Some(Object(map)) => {
      let entries : Array[GeoNameMapEntry] = []
      for from_name, to_json in map {
        match to_json {
          String(to_name) => entries.push({ from_name, to_name })
          _ => ()
        }
      }
      entries
    }
    _ => []
  }
}

///|
fn parse_geo_label_option(j : Json) -> GeoLabelOption {
  parse_geo_label_option_with_base(j, GeoLabelOption::default())
}

///|
fn parse_geo_label_option_with_base(
  j : Json,
  base : GeoLabelOption,
) -> GeoLabelOption {
  {
    show: j_bool(j, "show", base.show),
    color: j_string(j, "color", base.color),
    position: j_string_or_number_as_string_opt(j, "position", base.position),
    distance: match j_number_opt(j, "distance") {
      Some(v) => Some(v)
      None => base.distance
    },
    font_weight: match j_string_opt(j, "fontWeight") {
      Some(v) => Some(v)
      None => base.font_weight
    },
    rotate: match j_number_opt(j, "rotate") {
      Some(v) => Some(v)
      None => base.rotate
    },
    font_size: j_number(j, "fontSize", base.font_size),
    font_family: j_string(j, "fontFamily", base.font_family),
    formatter: match j_string_opt(j, "formatter") {
      Some(v) => Some(v)
      None => base.formatter
    },
  }
}

///|
fn parse_geo_label_patch_option(j : Json) -> GeoLabelPatchOption {
  {
    show: match j_field(j, "show") {
      Some(True) => Some(true)
      Some(False) => Some(false)
      _ => None
    },
    color: j_string_opt(j, "color"),
    position: j_string_opt(j, "position"),
    distance: j_number_opt(j, "distance"),
    font_weight: j_string_opt(j, "fontWeight"),
    rotate: j_number_opt(j, "rotate"),
    font_size: j_number_opt(j, "fontSize"),
    font_family: j_string_opt(j, "fontFamily"),
    formatter: j_string_opt(j, "formatter"),
  }
}

///|
fn parse_map_registry_option(j : Json) -> MapRegistryOption {
  {
    name: j_string(j, "name", ""),
    geo_json: match j_field(j, "geoJSON") {
      Some(value) => Some(value)
      None => j_field(j, "geoJson")
    },
    svg: j_string_opt(j, "svg"),
    special_areas: parse_map_special_areas(j),
  }
}

///|
fn parse_map_special_areas(j : Json) -> Array[MapSpecialAreaOption] {
  match j_field(j, "specialAreas") {
    Some(Object(map)) => {
      let result : Array[MapSpecialAreaOption] = []
      for name, value in map {
        result.push({
          name,
          left: j_number(value, "left", 0.0),
          top: j_number(value, "top", 0.0),
          width: j_number(value, "width", 0.0),
          height: j_number(value, "height", 0.0),
        })
      }
      result
    }
    _ => []
  }
}

///|
fn parse_calendar_option(j : Json) -> CalendarOption {
  let base = CalendarOption::default()
  {
    left: parse_size_spec_opt(j, "left", base.left),
    top: parse_size_spec_opt(j, "top", base.top),
    right: parse_size_spec_opt(j, "right", base.right),
    bottom: parse_size_spec_opt(j, "bottom", base.bottom),
    width: parse_size_spec_opt(j, "width", base.width),
    height: parse_size_spec_opt(j, "height", base.height),
    cell_size: parse_calendar_cell_size(j, base.cell_size),
    orient: j_string(j, "orient", base.orient),
    range: parse_calendar_range(j, base.range),
    split_line: parse_calendar_split_line(j),
    item_style: parse_calendar_item_style(j),
    day_label: parse_calendar_day_label(j),
    month_label: parse_calendar_month_label(j),
    year_label: parse_calendar_year_label(j),
  }
}

///|
fn parse_matrix_option(j : Json) -> MatrixOption {
  let base = MatrixOption::default()
  {
    left: parse_size_spec_opt(j, "left", base.left),
    top: parse_size_spec_opt(j, "top", base.top),
    right: parse_size_spec_opt(j, "right", base.right),
    bottom: parse_size_spec_opt(j, "bottom", base.bottom),
    width: parse_size_spec_opt(j, "width", base.width),
    height: parse_size_spec_opt(j, "height", base.height),
    x: parse_matrix_dimension_option(j_field_or_self(j, "x")),
    y: parse_matrix_dimension_option(j_field_or_self(j, "y")),
    body: parse_matrix_body_option(j_field_or_self(j, "body")),
    corner: parse_matrix_body_option(j_field_or_self(j, "corner")),
    background_style: parse_matrix_item_style_option(
      j_field_or_self(j, "backgroundStyle"),
      base.background_style,
    ),
    border_z2: j_number_opt(j, "borderZ2"),
  }
}

///|
fn parse_matrix_dimension_option(j : Json) -> MatrixDimensionOption {
  let base = MatrixDimensionOption::default()
  {
    show: j_bool(j, "show", base.show),
    data: parse_matrix_dimension_cells(j_field(j, "data")),
    length: match j_field(j, "length") {
      Some(Number(n, ..)) => Some(n.to_int())
      _ => base.length
    },
    level_size: parse_size_spec_opt(j, "levelSize", base.level_size),
    levels: parse_matrix_dimension_levels(j),
    item_style: parse_matrix_item_style_option(
      j_field_or_self(j, "itemStyle"),
      base.item_style,
    ),
    label: parse_matrix_label_option(j_field_or_self(j, "label"), base.label),
    divider_line_style: parse_matrix_line_style_option(
      j_field_or_self(j, "dividerLineStyle"),
      base.divider_line_style,
    ),
  }
}

///|
fn parse_matrix_dimension_levels(j : Json) -> Array[MatrixDimensionLevelOption] {
  match j_field(j, "levels") {
    Some(Array(arr)) => {
      let out : Array[MatrixDimensionLevelOption] = []
      let mut i = 0
      while i < arr.length() {
        out.push({ level_size: parse_size_spec_opt(arr[i], "levelSize", None) })
        i += 1
      }
      out
    }
    _ => []
  }
}

///|
fn parse_matrix_dimension_cells(j : Json?) -> Array[MatrixDimensionCellOption] {
  match j {
    Some(Array(arr)) => arr.map(parse_matrix_dimension_cell)
    _ => []
  }
}

///|
fn parse_matrix_dimension_cell(j : Json) -> MatrixDimensionCellOption {
  match j {
    String(s) =>
      {
        value: Some(s),
        size: None,
        children: [],
        item_style: None,
        label: None,
      }
    Number(n, ..) =>
      {
        value: Some("\{n}"),
        size: None,
        children: [],
        item_style: None,
        label: None,
      }
    _ =>
      {
        value: j_string_opt(j, "value"),
        size: parse_size_spec_opt(j, "size", None),
        children: parse_matrix_dimension_cells(j_field(j, "children")),
        item_style: parse_matrix_item_style_optional(j_field(j, "itemStyle")),
        label: parse_matrix_label_optional(j_field(j, "label")),
      }
  }
}

///|
fn parse_matrix_body_option(j : Json) -> MatrixBodyOption {
  let base = MatrixBodyOption::default()
  {
    data: parse_matrix_body_cells(j_field(j, "data")),
    item_style: parse_matrix_item_style_option(
      j_field_or_self(j, "itemStyle"),
      base.item_style,
    ),
    label: parse_matrix_label_option(j_field_or_self(j, "label"), base.label),
  }
}

///|
fn parse_matrix_body_cells(j : Json?) -> Array[MatrixBodyCellOption] {
  match j {
    Some(Array(arr)) => arr.map(parse_matrix_body_cell)
    _ => []
  }
}

///|
fn parse_matrix_body_cell(j : Json) -> MatrixBodyCellOption {
  {
    coord: parse_matrix_coord_pair(j_field(j, "coord")),
    value: j_string_opt(j, "value"),
    item_style: parse_matrix_item_style_optional(j_field(j, "itemStyle")),
    label: parse_matrix_label_optional(j_field(j, "label")),
    coord_clamp: j_bool(j, "coordClamp", false),
    merge_cells: j_bool(j, "mergeCells", false),
  }
}

///|
fn parse_matrix_coord_pair(j : Json?) -> Array[MatrixCoordPart] {
  match j {
    Some(Array(arr)) => {
      let out : Array[MatrixCoordPart] = []
      let mut i = 0
      while i < arr.length() && i < 2 {
        out.push(parse_matrix_coord_part(arr[i]))
        i += 1
      }
      out
    }
    _ => []
  }
}

///|
fn parse_matrix_coord_part(j : Json) -> MatrixCoordPart {
  match j {
    Null => Missing
    Array(arr) =>
      if arr.length() == 0 {
        Missing
      } else if arr.length() == 1 {
        Value(parse_matrix_coord_value(arr[0]))
      } else {
        Range(
          parse_matrix_coord_value(arr[0]),
          parse_matrix_coord_value(arr[arr.length() - 1]),
        )
      }
    _ => Value(parse_matrix_coord_value(j))
  }
}

///|
fn parse_matrix_coord_value(j : Json) -> MatrixCoordValue {
  match j {
    Number(n, ..) => Locator(n.to_int())
    Null => Missing
    String(s) => {
      let parsed = try? @string.parse_int(s, base=10)
      match parsed {
        Ok(v) => Locator(v)
        Err(_) => Name(s)
      }
    }
    _ => Missing
  }
}

///|
fn parse_matrix_item_style_optional(j : Json?) -> MatrixItemStyleOption? {
  match j {
    Some(value) =>
      Some(
        parse_matrix_item_style_option(value, MatrixItemStyleOption::default()),
      )
    None => None
  }
}

///|
fn parse_matrix_item_style_option(
  j : Json,
  base : MatrixItemStyleOption,
) -> MatrixItemStyleOption {
  {
    color: j_string(j, "color", base.color),
    border_color: j_string(j, "borderColor", base.border_color),
    border_width: j_number(j, "borderWidth", base.border_width),
  }
}

///|
fn parse_matrix_label_optional(j : Json?) -> MatrixLabelOption? {
  match j {
    Some(value) =>
      Some(parse_matrix_label_option(value, MatrixLabelOption::default()))
    None => None
  }
}

///|
fn parse_matrix_label_option(
  j : Json,
  base : MatrixLabelOption,
) -> MatrixLabelOption {
  {
    show: j_bool(j, "show", base.show),
    color: j_string(j, "color", base.color),
    font_size: j_number(j, "fontSize", base.font_size),
    font_family: j_string(j, "fontFamily", base.font_family),
    font_weight: j_string(j, "fontWeight", base.font_weight),
  }
}

///|
fn parse_matrix_line_style_option(
  j : Json,
  base : MatrixLineStyleOption,
) -> MatrixLineStyleOption {
  {
    color: j_string(j, "color", base.color),
    width: j_number(j, "width", base.width),
  }
}

///|
fn parse_size_spec(j : Json, key : String, default_val : SizeSpec) -> SizeSpec {
  match j_field(j, key) {
    Some(Number(n, ..)) => SizeSpec::Px(n)
    Some(String(s)) =>
      if s.has_suffix("%") {
        let pct_str = s[:s.length() - 1]
        let r = try? @string.parse_double(pct_str.to_string())
        match r {
          Ok(pct) => SizeSpec::Pct(pct)
          Err(_) => default_val
        }
      } else {
        let r = try? @string.parse_double(s)
        match r {
          Ok(px) => SizeSpec::Px(px)
          Err(_) => default_val
        }
      }
    _ => default_val
  }
}

///|
fn parse_size_spec_opt(
  j : Json,
  key : String,
  default_val : SizeSpec?,
) -> SizeSpec? {
  match j_field(j, key) {
    Some(Number(n, ..)) => Some(SizeSpec::Px(n))
    Some(String(s)) =>
      if s.has_suffix("%") {
        let pct_str = s[:s.length() - 1]
        let r = try? @string.parse_double(pct_str.to_string())
        r.map(pct => Some(SizeSpec::Pct(pct))).unwrap_or(default_val)
      } else {
        let r = try? @string.parse_double(s)
        r.map(px => Some(SizeSpec::Px(px))).unwrap_or(default_val)
      }
    _ => default_val
  }
}

///|
fn parse_sankey_level_option(j : Json) -> SankeyLevelOption {
  {
    depth: j_int(j, "depth", 0),
    label: match j_field(j, "label") {
      Some(value) => Some(parse_geo_label_patch_option(value))
      None => None
    },
    item_style: match j_field(j, "itemStyle") {
      Some(value) => Some(parse_geo_item_style_patch_option(value))
      None => None
    },
    line_style_color: match j_field(j, "lineStyle") {
      Some(value) => j_string_opt(value, "color")
      None => None
    },
    line_style_width: match j_field(j, "lineStyle") {
      Some(value) => j_number_opt(value, "width")
      None => None
    },
    line_style_opacity: match j_field(j, "lineStyle") {
      Some(value) => j_number_opt(value, "opacity")
      None => None
    },
    line_style_curveness: match j_field(j, "lineStyle") {
      Some(value) => j_number_opt(value, "curveness")
      None => None
    },
  }
}

///|
fn parse_treemap_upper_label_option(j : Json) -> TreemapUpperLabelOption {
  let base = TreemapUpperLabelOption::default()
  {
    show: j_bool(j, "show", base.show),
    height: j_number(j, "height", base.height),
  }
}

///|
fn parse_treemap_item_style_option(j : Json) -> TreemapItemStyleOption {
  {
    color: j_string_opt(j, "color"),
    border_color: j_string_opt(j, "borderColor"),
    border_width: j_number_opt(j, "borderWidth"),
    gap_width: j_number_opt(j, "gapWidth"),
  }
}

///|
fn parse_treemap_level_option(j : Json) -> TreemapLevelOption {
  {
    item_style: match j_field(j, "itemStyle") {
      Some(value) => Some(parse_treemap_item_style_option(value))
      None => None
    },
    upper_label: match j_field(j, "upperLabel") {
      Some(value) => Some(parse_treemap_upper_label_option(value))
      None => None
    },
    color_saturation: match j_field(j, "colorSaturation") {
      Some(Array(arr)) => Some(arr.map(json_number_or_zero))
      _ => None
    },
    color_alpha: match j_field(j, "colorAlpha") {
      Some(Array(arr)) => Some(arr.map(json_number_or_zero))
      _ => None
    },
  }
}

///|
fn parse_series_option(j : Json) -> SeriesOption {
  let series_type = match j_string(j, "type", "line") {
    "line" => SeriesType::Line
    "parallel" => SeriesType::Parallel
    "lines" => SeriesType::Lines
    "bar" => SeriesType::Bar
    "pictorialBar" => SeriesType::PictorialBar
    "scatter" => SeriesType::Scatter
    "effectScatter" => SeriesType::EffectScatter
    "pie" => SeriesType::Pie
    "sunburst" => SeriesType::Sunburst
    "treemap" => SeriesType::Treemap
    "radar" => SeriesType::Radar
    "candlestick" => SeriesType::Candlestick
    "heatmap" => SeriesType::Heatmap
    "boxplot" => SeriesType::Boxplot
    "funnel" => SeriesType::Funnel
    "gauge" => SeriesType::Gauge
    "map" => SeriesType::Map
    "themeRiver" => SeriesType::ThemeRiver
    "tree" => SeriesType::Tree
    "chord" => SeriesType::Chord
    "sankey" => SeriesType::Sankey
    "graph" => SeriesType::Graph
    _ => SeriesType::Line
  }
  let base = match series_type {
    Line => SeriesOption::default_line()
    Parallel => SeriesOption::default_parallel()
    Lines => SeriesOption::default_lines()
    Bar => SeriesOption::default_bar()
    PictorialBar => SeriesOption::default_pictorial_bar()
    Scatter => SeriesOption::default_scatter()
    EffectScatter => SeriesOption::default_effect_scatter()
    Pie => SeriesOption::default_pie()
    Sunburst => SeriesOption::default_sunburst()
    Treemap => SeriesOption::default_treemap()
    Gauge => SeriesOption::default_gauge()
    Map => SeriesOption::default_map()
    ThemeRiver => SeriesOption::default_theme_river()
    Funnel => SeriesOption::default_funnel()
    Tree => SeriesOption::default_tree()
    Chord => SeriesOption::default_chord()
    Sankey => SeriesOption::default_sankey()
    Graph => SeriesOption::default_graph()
    _ => SeriesOption::default_line()
  }
  // Note: Candlestick, Heatmap, Boxplot, Radar use default_line as base defaults.
  let data = match j_field(j, "data") {
    Some(Array(arr)) =>
      if series_type == SeriesType::ThemeRiver {
        arr.map(parse_data_item_theme_river)
      } else if series_type == SeriesType::Lines &&
        arr.length() > 0 &&
        arr[0] is Number(_, ..) {
        parse_lines_flat_data(arr)
      } else {
        arr.map(parse_data_item)
      }
    None =>
      match j_field(j, "nodes") {
        Some(Array(arr)) => arr.map(parse_data_item)
        _ => base.data
      }
    _ => base.data
  }
  let link_data = match j_field(j, "links") {
    Some(Array(arr)) => arr.map(parse_data_item)
    None =>
      match j_field(j, "edges") {
        Some(Array(arr)) => arr.map(parse_data_item)
        _ => base.link_data
      }
    _ => base.link_data
  }
  let name = j_string_opt(j, "name")
  let x_axis_index = j_int(j, "xAxisIndex", base.x_axis_index)
  let y_axis_index = j_int(j, "yAxisIndex", base.y_axis_index)
  let parallel_index = j_int(j, "parallelIndex", base.parallel_index)
  let radius_axis_index = j_int(j, "radiusAxisIndex", base.radius_axis_index)
  let angle_axis_index = j_int(j, "angleAxisIndex", base.angle_axis_index)
  let polar_index = j_int(j, "polarIndex", base.polar_index)
  let coordinate_system = match j_string_opt(j, "coordinateSystem") {
    Some(value) => Some(value)
    None => base.coordinate_system
  }
  let calendar_index = j_int(j, "calendarIndex", base.calendar_index)
  let matrix_index = j_int(j, "matrixIndex", base.matrix_index)
  let geo_index = j_int(j, "geoIndex", base.geo_index)
  let radar_index = j_int(j, "radarIndex", base.radar_index)
  let map_name = j_string_opt(j, "map")
  let show_legend_symbol = j_bool(
    j,
    "showLegendSymbol",
    base.show_legend_symbol,
  )
  let zoom = j_number(j, "zoom", base.zoom)
  let left = j_string_or_number_as_string_opt(j, "left", base.left)
  let top = j_string_or_number_as_string_opt(j, "top", base.top)
  let right = j_string_or_number_as_string_opt(j, "right", base.right)
  let bottom = j_string_or_number_as_string_opt(j, "bottom", base.bottom)
  let width = j_string_or_number_as_string_opt(j, "width", base.width)
  let height = j_string_or_number_as_string_opt(j, "height", base.height)
  let layout_center = match j_field(j, "layoutCenter") {
    Some(_) => Some(j_stringish_array(j, "layoutCenter", []))
    None => base.layout_center
  }
  let layout_size = j_string_or_number_as_string_opt(
    j,
    "layoutSize",
    base.layout_size,
  )
  let bounding_coords = match j_field(j, "boundingCoords") {
    Some(Array(arr)) => pair_number_arrays_from_json(arr)
    _ => base.bounding_coords
  }
  let name_property = match j_string_opt(j, "nameProperty") {
    Some(value) => Some(value)
    None => base.name_property
  }
  let boundary_gap = j_stringish_array(j, "boundaryGap", base.boundary_gap)
  let symbol_values = parse_symbol_values(j)
  let symbol_size_values = parse_symbol_size_values(j)
  let symbol_size = j_number(j, "symbolSize", base.symbol_size)
  let symbol = j_string_or_number_as_string_opt(j, "symbol", base.symbol)
  let (symbol_repeat, symbol_repeat_count, symbol_repeat_fixed) = parse_symbol_repeat(
    j, base,
  )
  let symbol_margin = j_string_or_number_as_string_opt(
    j,
    "symbolMargin",
    base.symbol_margin,
  )
  let symbol_clip = j_bool(j, "symbolClip", base.symbol_clip)
  let symbol_position = j_string_or_number_as_string_opt(
    j,
    "symbolPosition",
    base.symbol_position,
  )
  let symbol_rotate = j_number_opt(j, "symbolRotate")
  let symbol_bounding_data = parse_symbol_bounding_data(j)
  let symbol_offset = parse_symbol_offset(j)
  let symbol_repeat_direction = j_string_or_number_as_string_opt(
    j,
    "symbolRepeatDirection",
    base.symbol_repeat_direction,
  )
  let bar_width = j_string_or_number_as_string_opt(j, "barWidth", None)
  let bar_max_width = j_string_or_number_as_string_opt(j, "barMaxWidth", None)
  let bar_min_width = j_string_or_number_as_string_opt(j, "barMinWidth", None)
  let bar_gap = j_string_or_number_as_string_opt(j, "barGap", base.bar_gap)
  let bar_category_gap = j_string_or_number_as_string_opt(
    j,
    "barCategoryGap",
    base.bar_category_gap,
  )
  let bar_min_height = j_number(j, "barMinHeight", base.bar_min_height)
  let bar_min_angle = j_number(j, "barMinAngle", base.bar_min_angle)
  let large = j_bool(j, "large", base.large)
  let large_threshold = j_int(j, "largeThreshold", base.large_threshold)
  let round_cap = j_bool(j, "roundCap", base.round_cap)
  let show_background = j_bool(j, "showBackground", base.show_background)
  let funnel_sort = j_string(j, "sort", base.funnel_sort)
  let funnel_orient = j_string(j, "orient", base.funnel_orient)
  let funnel_gap = j_number(j, "gap", base.funnel_gap)
  let funnel_align = j_string(j, "funnelAlign", base.funnel_align)
  let funnel_min = j_number_opt(j, "min")
  let funnel_max = j_number_opt(j, "max")
  let funnel_min_size = j_string_or_number_as_string_opt(
    j,
    "minSize",
    Some(base.funnel_min_size),
  ).unwrap_or(base.funnel_min_size)
  let funnel_max_size = j_string_or_number_as_string_opt(
    j,
    "maxSize",
    Some(base.funnel_max_size),
  ).unwrap_or(base.funnel_max_size)
  let background_style = match j_field(j, "backgroundStyle") {
    Some(style) => Some(parse_geo_item_style_patch_option(style))
    None => base.background_style
  }
  let color = match j_color_opt(j, "color") {
    Some(c) => Some(c)
    None => base.color
  }
  let item_style = match j_field(j, "itemStyle") {
    Some(style) => j_color_opt(style, "color")
    _ => None
  }
  // Candlestick-specific itemStyle fields
  // Corresponds to: echarts/src/chart/candlestick/CandlestickSeries.ts
  let candle_item_style = j_field(j, "itemStyle")
  let candle_color_up = match candle_item_style {
    Some(style) => j_color_opt(style, "color")
    None => base.candle_color_up
  }
  let candle_color_down = match candle_item_style {
    Some(style) => j_color_opt(style, "color0")
    None => base.candle_color_down
  }
  let candle_border_color_up = match candle_item_style {
    Some(style) => j_color_opt(style, "borderColor")
    None => base.candle_border_color_up
  }
  let candle_border_color_down = match candle_item_style {
    Some(style) => j_color_opt(style, "borderColor0")
    None => base.candle_border_color_down
  }
  let candle_border_width = match candle_item_style {
    Some(style) => j_number(style, "borderWidth", base.candle_border_width)
    None => base.candle_border_width
  }
  let geo_item_style = match j_field(j, "itemStyle") {
    Some(style) => Some(parse_geo_item_style_patch_option(style))
    None => None
  }
  let item_opacity = match j_field(j, "itemStyle") {
    Some(style) =>
      match j_field(style, "opacity") {
        Some(Number(n, ..)) => Some(n)
        _ => None
      }
    _ => None
  }
  let label = match j_field(j, "label") {
    Some(value) =>
      Some(
        parse_geo_label_option_with_base(
          value,
          base.label.unwrap_or(GeoLabelOption::default()),
        ),
      )
    None => base.label
  }
  let area_style = match j_field(j, "areaStyle") {
    None => base.area_style
    Some(Null) => base.area_style
    Some(_) => true
  }
  let stack = j_string_opt(j, "stack")
  let smooth = j_bool(j, "smooth", base.smooth)
  let polyline = j_bool(j, "polyline", base.polyline)
  let clip = j_bool(j, "clip", base.clip)
  let line_style = j_field_or_self(j, "lineStyle")
  let line_style_color = match j_color_opt(line_style, "color") {
    Some(color) => Some(color)
    None => base.line_style_color
  }
  let line_style_width = match j_number_opt(line_style, "width") {
    Some(width) => Some(width)
    None => base.line_style_width
  }
  let line_style_opacity = match j_number_opt(line_style, "opacity") {
    Some(opacity) => Some(opacity)
    None => base.line_style_opacity
  }
  let line_style_curveness = j_number_opt(line_style, "curveness")
  let radius = j_stringish_array(j, "radius", base.radius)
  let center = j_stringish_array(j, "center", base.center)
  let min_angle = j_number(j, "minAngle", base.min_angle)
  let pad_angle = j_number(j, "padAngle", base.pad_angle)
  let clockwise = j_bool(j, "clockwise", base.clockwise)
  let start_angle = j_number(j, "startAngle", base.start_angle)
  let end_angle = j_number(j, "endAngle", base.end_angle)
  let min_val = j_number(j, "min", base.min_val)
  let max_val = j_number(j, "max", base.max_val)
  let split_number = j_int(j, "splitNumber", base.split_number)
  // Gauge-specific: progress, title, detail
  let gauge_progress = j_field(j, "progress")
  let gauge_progress_show = match gauge_progress {
    Some(p) => j_bool(p, "show", base.gauge_progress_show)
    None => base.gauge_progress_show
  }
  let gauge_progress_overlap = match gauge_progress {
    Some(p) => j_bool(p, "overlap", base.gauge_progress_overlap)
    None => base.gauge_progress_overlap
  }
  let gauge_progress_width = match gauge_progress {
    Some(p) => j_number(p, "width", base.gauge_progress_width)
    None => base.gauge_progress_width
  }
  let gauge_progress_round_cap = match gauge_progress {
    Some(p) => j_bool(p, "roundCap", base.gauge_progress_round_cap)
    None => base.gauge_progress_round_cap
  }
  let gauge_progress_clip = match gauge_progress {
    Some(p) => j_bool(p, "clip", base.gauge_progress_clip)
    None => base.gauge_progress_clip
  }
  let gauge_round_cap = match j_field(j, "axisLine") {
    Some(al) => j_bool(al, "roundCap", base.gauge_round_cap)
    None => base.gauge_round_cap
  }
  let gauge_detail_obj = j_field(j, "detail")
  let gauge_detail_formatter = match gauge_detail_obj {
    Some(d) => j_string_opt(d, "formatter")
    None => base.gauge_detail_formatter
  }
  let gauge_detail_color = match gauge_detail_obj {
    Some(d) => j_string_opt(d, "color")
    None => base.gauge_detail_color
  }
  let gauge_detail_font_size = match gauge_detail_obj {
    Some(d) => j_number(d, "fontSize", base.gauge_detail_font_size)
    None => base.gauge_detail_font_size
  }
  let gauge_detail_offset_center = match gauge_detail_obj {
    Some(d) =>
      match j_field(d, "offsetCenter") {
        Some(Array(arr)) =>
          arr.map(fn(x) {
            match x {
              String(s) => s
              Number(n, ..) => "\{n}"
              _ => "0"
            }
          })
        _ => base.gauge_detail_offset_center
      }
    None => base.gauge_detail_offset_center
  }
  let gauge_title_obj = j_field(j, "title")
  let gauge_title_font_size = match gauge_title_obj {
    Some(t) => j_number(t, "fontSize", base.gauge_title_font_size)
    None => base.gauge_title_font_size
  }
  let gauge_title_offset_center = match gauge_title_obj {
    Some(t) =>
      match j_field(t, "offsetCenter") {
        Some(Array(arr)) =>
          arr.map(fn(x) {
            match x {
              String(s) => s
              Number(n, ..) => "\{n}"
              _ => "0"
            }
          })
        _ => base.gauge_title_offset_center
      }
    None => base.gauge_title_offset_center
  }
  // Gauge axisLine styling
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderMain
  let gauge_axis_line_obj = j_field(j, "axisLine")
  let gauge_axis_line_line_style = gauge_axis_line_obj.bind(al => {
    j_field(al, "lineStyle")
  })
  let gauge_axis_line_colors : Array[(Double, String)] = match
    gauge_axis_line_line_style.bind(ls => j_field(ls, "color")) {
    Some(Array(arr)) => {
      let result : Array[(Double, String)] = []
      for entry in arr {
        match entry {
          Array([Number(offset, ..), String(color)]) =>
            result.push((offset, color))
          _ => ()
        }
      }
      if result.is_empty() {
        base.gauge_axis_line_colors
      } else {
        result
      }
    }
    _ => base.gauge_axis_line_colors
  }
  let gauge_axis_line_width = match gauge_axis_line_line_style {
    Some(ls) => j_number(ls, "width", base.gauge_axis_line_width)
    None => base.gauge_axis_line_width
  }
  // Gauge splitLine styling
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderTicks splitLine
  let gauge_split_line_obj = j_field(j, "splitLine")
  let gauge_split_line_show = match gauge_split_line_obj {
    Some(sl) => j_bool(sl, "show", base.gauge_split_line_show)
    None => base.gauge_split_line_show
  }
  let gauge_split_line_length = match gauge_split_line_obj {
    Some(sl) => j_number(sl, "length", base.gauge_split_line_length)
    None => base.gauge_split_line_length
  }
  let gauge_split_line_distance = match gauge_split_line_obj {
    Some(sl) => j_number(sl, "distance", base.gauge_split_line_distance)
    None => base.gauge_split_line_distance
  }
  let gauge_split_line_line_style = gauge_split_line_obj.bind(sl => {
    j_field(sl, "lineStyle")
  })
  let gauge_split_line_color = match gauge_split_line_line_style {
    Some(ls) => j_string(ls, "color", base.gauge_split_line_color)
    None => base.gauge_split_line_color
  }
  let gauge_split_line_width = match gauge_split_line_line_style {
    Some(ls) => j_number(ls, "width", base.gauge_split_line_width)
    None => base.gauge_split_line_width
  }
  // Gauge axisTick styling
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderTicks axisTick
  let gauge_axis_tick_obj = j_field(j, "axisTick")
  let gauge_axis_tick_show = match gauge_axis_tick_obj {
    Some(t) => j_bool(t, "show", base.gauge_axis_tick_show)
    None => base.gauge_axis_tick_show
  }
  let gauge_axis_tick_length = match gauge_axis_tick_obj {
    Some(t) => j_number(t, "length", base.gauge_axis_tick_length)
    None => base.gauge_axis_tick_length
  }
  let gauge_axis_tick_distance = match gauge_axis_tick_obj {
    Some(t) => j_number(t, "distance", base.gauge_axis_tick_distance)
    None => base.gauge_axis_tick_distance
  }
  let gauge_axis_tick_split_number = match gauge_axis_tick_obj {
    Some(t) => j_int(t, "splitNumber", base.gauge_axis_tick_split_number)
    None => base.gauge_axis_tick_split_number
  }
  let gauge_axis_tick_line_style = gauge_axis_tick_obj.bind(t => {
    j_field(t, "lineStyle")
  })
  let gauge_axis_tick_color = match gauge_axis_tick_line_style {
    Some(ls) => j_string(ls, "color", base.gauge_axis_tick_color)
    None => base.gauge_axis_tick_color
  }
  let gauge_axis_tick_width = match gauge_axis_tick_line_style {
    Some(ls) => j_number(ls, "width", base.gauge_axis_tick_width)
    None => base.gauge_axis_tick_width
  }
  // Gauge axisLabel styling
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderTicks axisLabel
  let gauge_axis_label_obj = j_field(j, "axisLabel")
  let gauge_axis_label_show = match gauge_axis_label_obj {
    Some(l) => j_bool(l, "show", base.gauge_axis_label_show)
    None => base.gauge_axis_label_show
  }
  let gauge_axis_label_color = match gauge_axis_label_obj {
    Some(l) => j_string(l, "color", base.gauge_axis_label_color)
    None => base.gauge_axis_label_color
  }
  let gauge_axis_label_distance = match gauge_axis_label_obj {
    Some(l) => j_number(l, "distance", base.gauge_axis_label_distance)
    None => base.gauge_axis_label_distance
  }
  let gauge_axis_label_font_size = match gauge_axis_label_obj {
    Some(l) => j_number(l, "fontSize", base.gauge_axis_label_font_size)
    None => base.gauge_axis_label_font_size
  }
  // Gauge pointer styling
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderPointer
  let gauge_pointer_obj = j_field(j, "pointer")
  let gauge_pointer_show = match gauge_pointer_obj {
    Some(p) => j_bool(p, "show", base.gauge_pointer_show)
    None => base.gauge_pointer_show
  }
  let gauge_pointer_item_style = gauge_pointer_obj.bind(p => {
    j_field(p, "itemStyle")
  })
  let gauge_pointer_color = match gauge_pointer_item_style {
    Some(pis) => j_string_opt(pis, "color")
    None => base.gauge_pointer_color
  }
  let gauge_pointer_length = match gauge_pointer_obj {
    Some(p) => j_string_or_number(p, "length", base.gauge_pointer_length)
    None => base.gauge_pointer_length
  }
  let gauge_pointer_width = match gauge_pointer_obj {
    Some(p) => j_number(p, "width", base.gauge_pointer_width)
    None => base.gauge_pointer_width
  }
  let gauge_pointer_icon = match gauge_pointer_obj {
    Some(p) => j_string_opt(p, "icon")
    None => base.gauge_pointer_icon
  }
  let gauge_pointer_offset_center = match
    gauge_pointer_obj.bind(p => j_field(p, "offsetCenter")) {
    Some(Array(arr)) =>
      arr.map(fn(x) {
        match x {
          String(s) => s
          Number(n, ..) => "\{n}"
          _ => "0"
        }
      })
    _ => base.gauge_pointer_offset_center
  }
  // Gauge anchor styling
  // Corresponds to: echarts/src/chart/gauge/GaugeView.ts _renderAnchor
  let gauge_anchor_obj = j_field(j, "anchor")
  let gauge_anchor_show = match gauge_anchor_obj {
    Some(a) => j_bool(a, "show", base.gauge_anchor_show)
    None => base.gauge_anchor_show
  }
  let gauge_anchor_size = match gauge_anchor_obj {
    Some(a) => j_number(a, "size", base.gauge_anchor_size)
    None => base.gauge_anchor_size
  }
  let gauge_anchor_item_style = gauge_anchor_obj.bind(a => {
    j_field(a, "itemStyle")
  })
  let gauge_anchor_color = match gauge_anchor_item_style {
    Some(ais) => j_string_opt(ais, "color")
    None => base.gauge_anchor_color
  }
  let gauge_anchor_border_color = match gauge_anchor_item_style {
    Some(ais) => j_string_opt(ais, "borderColor")
    None => base.gauge_anchor_border_color
  }
  let gauge_anchor_border_width = match gauge_anchor_item_style {
    Some(ais) => j_number(ais, "borderWidth", base.gauge_anchor_border_width)
    None => base.gauge_anchor_border_width
  }
  let map_value_calculation = match j_string(j, "mapValueCalculation", "sum") {
    "average" => MapValueCalculationType::Average
    "min" => MapValueCalculationType::Min
    "max" => MapValueCalculationType::Max
    _ => MapValueCalculationType::Sum
  }
  let active_opacity = j_number_opt(j, "activeOpacity")
  let inactive_opacity = j_number_opt(j, "inactiveOpacity")
  let silent = j_bool(j, "silent", base.silent)
  let states = parse_geo_states_option(j)
  // tree chart options
  let tree_layout = j_string(j, "layout", base.tree_layout)
  let tree_orient = j_string(j, "orient", base.tree_orient)
  let tree_edge_shape = j_string(j, "edgeShape", base.tree_edge_shape)
  let tree_edge_fork_position = j_string(
    j,
    "edgeForkPosition",
    base.tree_edge_fork_position,
  )
  let tree_expand_and_collapse = j_bool(
    j,
    "expandAndCollapse",
    base.tree_expand_and_collapse,
  )
  let tree_initial_depth = j_int(j, "initialTreeDepth", base.tree_initial_depth)
  let tree_left = j_string(j, "left", base.tree_left)
  let tree_top = j_string(j, "top", base.tree_top)
  let tree_right = j_string(j, "right", base.tree_right)
  let tree_bottom = j_string(j, "bottom", base.tree_bottom)
  let tree_node_scale_ratio = j_number(
    j,
    "nodeScaleRatio",
    base.tree_node_scale_ratio,
  )
  let tree_leaves = j_field(j, "leaves")
  let tree_leaves_label = match tree_leaves {
    Some(leaves) =>
      match j_field(leaves, "label") {
        Some(value) => Some(parse_geo_label_patch_option(value))
        None => None
      }
    None => None
  }
  let tree_leaves_geo_item_style = match tree_leaves {
    Some(leaves) =>
      j_field(leaves, "itemStyle").map(parse_geo_item_style_patch_option)
    None => None
  }
  let tree_leaves_symbol = tree_leaves.bind(l => {
    j_string_or_number_as_string_opt(l, "symbol", None)
  })
  let tree_leaves_symbol_size = tree_leaves.bind(l => {
    j_number_opt(l, "symbolSize")
  })
  let tree_leaves_line_style = tree_leaves.bind(l => j_field(l, "lineStyle"))
  let tree_leaves_line_style_color = tree_leaves_line_style.bind(style => {
    j_string_opt(style, "color")
  })
  let tree_leaves_line_style_width = tree_leaves_line_style.bind(style => {
    j_number_opt(style, "width")
  })
  let tree_leaves_line_style_opacity = tree_leaves_line_style.bind(style => {
    j_number_opt(style, "opacity")
  })
  let tree_leaves_line_style_curveness = tree_leaves_line_style.bind(style => {
    j_number_opt(style, "curveness")
  })
  let sankey_orient = j_string(j, "orient", base.sankey_orient)
  let sankey_node_width = j_number(j, "nodeWidth", base.sankey_node_width)
  let sankey_node_gap = j_number(j, "nodeGap", base.sankey_node_gap)
  let sankey_layout_iterations = j_int(
    j,
    "layoutIterations",
    base.sankey_layout_iterations,
  )
  let sankey_node_align = j_string(j, "nodeAlign", base.sankey_node_align)
  let sankey_left = parse_size_spec_opt(j, "left", base.sankey_left)
  let sankey_top = parse_size_spec_opt(j, "top", base.sankey_top)
  let sankey_right = parse_size_spec_opt(j, "right", base.sankey_right)
  let sankey_bottom = parse_size_spec_opt(j, "bottom", base.sankey_bottom)
  let sankey_width = parse_size_spec_opt(j, "width", base.sankey_width)
  let sankey_height = parse_size_spec_opt(j, "height", base.sankey_height)
  let sankey_levels = j_parse_array(j, "levels", parse_sankey_level_option, [])
  let treemap_upper_label = match j_field(j, "upperLabel") {
    Some(value) => Some(parse_treemap_upper_label_option(value))
    None => base.treemap_upper_label
  }
  let treemap_item_style = match j_field(j, "itemStyle") {
    Some(value) => Some(parse_treemap_item_style_option(value))
    None => base.treemap_item_style
  }
  let treemap_levels = j_parse_array(j, "levels", parse_treemap_level_option, [])
  // Graph-specific fields
  // Corresponds to: echarts/src/chart/graph/GraphSeries.ts
  let graph_layout = j_string(j, "layout", base.graph_layout)
  let graph_categories = match j_field(j, "categories") {
    Some(Array(arr)) =>
      arr.map(fn(cat) {
        match j_field(cat, "name") {
          Some(String(s)) => s
          _ => ""
        }
      })
    _ => base.graph_categories
  }
  let graph_force_obj = j_field(j, "force")
  let graph_force_edge_length = match graph_force_obj {
    Some(f) => j_number(f, "edgeLength", base.graph_force_edge_length)
    None => base.graph_force_edge_length
  }
  let graph_force_repulsion = match graph_force_obj {
    Some(f) => j_number(f, "repulsion", base.graph_force_repulsion)
    None => base.graph_force_repulsion
  }
  let graph_force_gravity = match graph_force_obj {
    Some(f) => j_number(f, "gravity", base.graph_force_gravity)
    None => base.graph_force_gravity
  }
  let pie_rose_type = match j_string_opt(j, "roseType") {
    Some("radius") => Some("radius")
    Some("area") => Some("area")
    _ => base.pie_rose_type
  }
  let end_angle = match j_field(j, "endAngle") {
    Some(Number(n, ..)) => n
    Some(String("auto")) => 0.0 / 0.0
    _ => end_angle
  }
  let pie_min_show_label_angle = j_number(
    j,
    "minShowLabelAngle",
    base.pie_min_show_label_angle,
  )
  let pie_avoid_label_overlap = j_bool(
    j,
    "avoidLabelOverlap",
    base.pie_avoid_label_overlap,
  )
  let pie_percent_precision = j_int(
    j,
    "percentPrecision",
    base.pie_percent_precision,
  )
  let pie_still_show_zero_sum = j_bool(
    j,
    "stillShowZeroSum",
    base.pie_still_show_zero_sum,
  )
  let pie_show_empty_circle = j_bool(
    j,
    "showEmptyCircle",
    base.pie_show_empty_circle,
  )
  let pie_empty_circle_color = match j_field(j, "emptyCircleStyle") {
    Some(v) =>
      match j_color_opt(v, "color") {
        Some(c) => Some(c)
        None => base.pie_empty_circle_color
      }
    None => base.pie_empty_circle_color
  }
  let pie_label_line_show = match j_field(j, "labelLine") {
    Some(v) => j_bool(v, "show", base.pie_label_line_show)
    None => base.pie_label_line_show
  }
  let pie_label_line_length = match j_field(j, "labelLine") {
    Some(v) => j_number(v, "length", base.pie_label_line_length)
    None => base.pie_label_line_length
  }
  let pie_label_line_length2 = match j_field(j, "labelLine") {
    Some(v) => j_number(v, "length2", base.pie_label_line_length2)
    None => base.pie_label_line_length2
  }
  {
    series_type,
    name,
    data,
    original_data: None,
    link_data,
    symbol,
    symbol_values,
    symbol_size_values,
    symbol_repeat,
    symbol_repeat_count,
    symbol_repeat_fixed,
    symbol_margin,
    symbol_clip,
    symbol_position,
    symbol_rotate,
    symbol_bounding_data,
    symbol_offset,
    symbol_repeat_direction,
    bar_width,
    bar_max_width,
    bar_min_width,
    bar_gap,
    bar_category_gap,
    bar_min_height,
    bar_min_angle,
    large,
    large_threshold,
    round_cap,
    show_background,
    funnel_sort,
    funnel_orient,
    funnel_gap,
    funnel_align,
    funnel_min,
    funnel_max,
    funnel_min_size,
    funnel_max_size,
    x_axis_index,
    y_axis_index,
    parallel_index,
    radius_axis_index,
    angle_axis_index,
    polar_index,
    coordinate_system,
    calendar_index,
    matrix_index,
    geo_index,
    radar_index,
    map_name,
    show_legend_symbol,
    zoom,
    name_property,
    left,
    top,
    right,
    bottom,
    width,
    height,
    layout_center,
    layout_size,
    bounding_coords,
    stack,
    boundary_gap,
    smooth,
    polyline,
    clip,
    symbol_size,
    color,
    line_style_color,
    line_style_width,
    line_style_opacity,
    line_style_curveness,
    item_style,
    item_opacity,
    label,
    geo_item_style,
    background_style,
    silent,
    states,
    area_style,
    encode_x: None,
    encode_y: None,
    radius,
    center,
    min_angle,
    pad_angle,
    clockwise,
    start_angle,
    end_angle,
    min_val,
    max_val,
    split_number,
    map_value_calculation,
    active_opacity,
    inactive_opacity,
    tree_layout,
    tree_orient,
    tree_edge_shape,
    tree_edge_fork_position,
    tree_expand_and_collapse,
    tree_initial_depth,
    tree_left,
    tree_top,
    tree_right,
    tree_bottom,
    tree_node_scale_ratio,
    tree_leaves_label,
    tree_leaves_geo_item_style,
    tree_leaves_symbol,
    tree_leaves_symbol_size,
    tree_leaves_line_style_color,
    tree_leaves_line_style_width,
    tree_leaves_line_style_opacity,
    tree_leaves_line_style_curveness,
    sankey_orient,
    sankey_node_width,
    sankey_node_gap,
    sankey_layout_iterations,
    sankey_node_align,
    sankey_left,
    sankey_top,
    sankey_right,
    sankey_bottom,
    sankey_width,
    sankey_height,
    sankey_levels,
    treemap_upper_label,
    treemap_item_style,
    treemap_levels,
    gauge_progress_show,
    gauge_progress_overlap,
    gauge_progress_width,
    gauge_progress_round_cap,
    gauge_progress_clip,
    gauge_round_cap,
    gauge_detail_formatter,
    gauge_detail_color,
    gauge_detail_font_size,
    gauge_detail_offset_center,
    gauge_title_font_size,
    gauge_title_offset_center,
    gauge_axis_line_colors,
    gauge_axis_line_width,
    gauge_split_line_show,
    gauge_split_line_length,
    gauge_split_line_distance,
    gauge_split_line_color,
    gauge_split_line_width,
    gauge_axis_tick_show,
    gauge_axis_tick_length,
    gauge_axis_tick_distance,
    gauge_axis_tick_color,
    gauge_axis_tick_width,
    gauge_axis_tick_split_number,
    gauge_axis_label_show,
    gauge_axis_label_color,
    gauge_axis_label_distance,
    gauge_axis_label_font_size,
    gauge_pointer_show,
    gauge_pointer_color,
    gauge_pointer_length,
    gauge_pointer_width,
    gauge_pointer_offset_center,
    gauge_pointer_icon,
    gauge_anchor_show,
    gauge_anchor_size,
    gauge_anchor_color,
    gauge_anchor_border_color,
    gauge_anchor_border_width,
    candle_color_up,
    candle_color_down,
    candle_border_color_up,
    candle_border_color_down,
    candle_border_width,
    graph_layout,
    graph_categories,
    graph_force_edge_length,
    graph_force_repulsion,
    graph_force_gravity,
    pie_selected_offset: j_number(j, "selectedOffset", base.pie_selected_offset),
    pie_rose_type,
    pie_min_show_label_angle,
    pie_avoid_label_overlap,
    pie_percent_precision,
    pie_still_show_zero_sum,
    pie_show_empty_circle,
    pie_empty_circle_color,
    pie_label_line_show,
    pie_label_line_length,
    pie_label_line_length2,
  }
}

///|
fn parse_data_item(j : Json) -> DataItem {
  match j {
    Number(n, ..) =>
      {
        value: DataValue::Num(n),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        depth: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
        title_offset_center: None,
        detail_offset_center: None,
        highlighted: None,
      }
    String(s) => {
      let parsed = try? @string.parse_double(s)
      match parsed {
        Ok(n) =>
          {
            value: DataValue::Num(n),
            raw_value_parts: None,
            raw_item: None,
            id: None,
            name: None,
            depth: None,
            source: None,
            target: None,
            symbol: None,
            coords: None,
            from_name: None,
            to_name: None,
            cursor: None,
            selected: None,
            silent: None,
            label: None,
            item_style: None,
            states: GeoStatesOption::default(),
            children: [],
            collapsed: None,
            title_offset_center: None,
            detail_offset_center: None,
            highlighted: None,
          }
        Err(_) =>
          {
            value: DataValue::Null,
            raw_value_parts: None,
            raw_item: None,
            id: None,
            name: None,
            depth: None,
            source: None,
            target: None,
            symbol: None,
            coords: None,
            from_name: None,
            to_name: None,
            cursor: None,
            selected: None,
            silent: None,
            label: None,
            item_style: None,
            states: GeoStatesOption::default(),
            children: [],
            collapsed: None,
            title_offset_center: None,
            detail_offset_center: None,
            highlighted: None,
          }
      }
    }
    Null =>
      {
        value: DataValue::Null,
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        depth: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
        title_offset_center: None,
        detail_offset_center: None,
        highlighted: None,
      }
    True =>
      {
        value: DataValue::Num(1.0),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        depth: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
        title_offset_center: None,
        detail_offset_center: None,
        highlighted: None,
      }
    False =>
      {
        value: DataValue::Num(0.0),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        depth: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
        title_offset_center: None,
        detail_offset_center: None,
        highlighted: None,
      }
    Array(arr) => parse_data_array_item(arr)
    { "value": Number(n, ..), .. } => parse_data_object(j, DataValue::Num(n))
    { "value": Array(arr), .. } =>
      parse_data_object(j, parse_data_array_value(arr))
    Object(_) => parse_data_object(j, DataValue::Null)
  }
}

///|
fn parse_data_array_item(arr : Array[Json]) -> DataItem {
  {
    value: parse_data_array_value(arr),
    raw_value_parts: Some(arr),
    raw_item: None,
    id: None,
    name: None,
    depth: None,
    source: None,
    target: None,
    symbol: None,
    coords: None,
    from_name: None,
    to_name: None,
    cursor: None,
    selected: None,
    silent: None,
    label: None,
    item_style: None,
    states: GeoStatesOption::default(),
    children: [],
    collapsed: None,
    title_offset_center: None,
    detail_offset_center: None,
    highlighted: None,
  }
}

///|
fn parse_data_array_value(arr : Array[Json]) -> DataValue {
  match arr {
    [String(date), Number(n, ..)] => DataValue::DateValue(date, n)
    _ => DataValue::Vec(arr.map(json_number_or_zero))
  }
}

///|
// Corresponds to: ThemeRiverSeries.ts data format [date, value, name]
fn parse_data_item_theme_river(j : Json) -> DataItem {
  match j {
    Array([String(date), Number(val, ..), String(name)]) =>
      {
        value: DataValue::DateValue(date, val),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: Some(name),
        depth: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
        title_offset_center: None,
        detail_offset_center: None,
        highlighted: None,
      }
    Array([Number(x, ..), Number(val, ..), String(name)]) => {
      let key = if x.to_int().to_double() == x {
        x.to_int().to_string()
      } else {
        x.to_string()
      }
      {
        value: DataValue::DateValue(key, val),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: Some(name),
        depth: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
        title_offset_center: None,
        detail_offset_center: None,
        highlighted: None,
      }
    }
    Array([String(date), Number(val, ..)]) =>
      {
        value: DataValue::DateValue(date, val),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        depth: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
        title_offset_center: None,
        detail_offset_center: None,
        highlighted: None,
      }
    Array([Number(x, ..), Number(val, ..)]) => {
      let key = if x.to_int().to_double() == x {
        x.to_int().to_string()
      } else {
        x.to_string()
      }
      {
        value: DataValue::DateValue(key, val),
        raw_value_parts: None,
        raw_item: None,
        id: None,
        name: None,
        depth: None,
        source: None,
        target: None,
        symbol: None,
        coords: None,
        from_name: None,
        to_name: None,
        cursor: None,
        selected: None,
        silent: None,
        label: None,
        item_style: None,
        states: GeoStatesOption::default(),
        children: [],
        collapsed: None,
        title_offset_center: None,
        detail_offset_center: None,
        highlighted: None,
      }
    }
    _ => parse_data_item(j)
  }
}

///|
fn parse_data_coords(j : Json) -> Array[Array[Double]]? {
  match j_field(j, "coords") {
    Some(Array(coords_arr)) => {
      let coords : Array[Array[Double]] = []
      let mut i = 0
      while i < coords_arr.length() {
        match coords_arr[i] {
          Array(pair) => {
            let coord : Array[Double] = []
            let mut j = 0
            while j < pair.length() {
              match pair[j] {
                Number(n, ..) => coord.push(n)
                _ => ()
              }
              j += 1
            }
            if coord.length() >= 2 {
              coords.push(coord)
            }
          }
          _ => ()
        }
        i += 1
      }
      Some(coords)
    }
    _ => None
  }
}

///|
// ---- JSON access helpers ----

///|
/// Parse a single RadarOption from JSON.
/// Corresponds to echarts/src/coord/radar/RadarModel.ts option parsing.
fn parse_radar_option(j : Json) -> RadarOption {
  let base = RadarOption::default()
  let indicator = j_parse_array(j, "indicator", parse_radar_indicator, [])
  let center = j_stringish_array(j, "center", base.center)
  let radius = j_string_or_number(j, "radius", base.radius)
  let start_angle = j_number(j, "startAngle", base.start_angle)
  let clockwise = j_bool(j, "clockwise", base.clockwise)
  let split_number = j_int(j, "splitNumber", base.split_number)
  { indicator, center, radius, start_angle, clockwise, split_number }
}

///|
fn parse_radar_indicator(j : Json) -> RadarIndicator {
  let name = match j_field(j, "name") {
    Some(String(s)) => s
    _ => ""
  }
  let max = j_number_opt(j, "max")
  let min = j_number_opt(j, "min")
  { name, max, min }
}

///|
fn parse_calendar_cell_size(
  j : Json,
  default_val : Array[CalendarCellSize],
) -> Array[CalendarCellSize] {
  match j_field(j, "cellSize") {
    Some(value) =>
      match value {
        Number(n, ..) => [CalendarCellSize::Px(n), CalendarCellSize::Px(n)]
        String("auto") => [CalendarCellSize::Auto, CalendarCellSize::Auto]
        Array(arr) => {
          let parsed : Array[CalendarCellSize] = []
          let mut i = 0
          while i < arr.length() && i < 2 {
            parsed.push(parse_calendar_cell_size_item(arr[i]))
            i += 1
          }
          if parsed.length() == 1 {
            parsed.push(parsed[0])
          }
          if parsed.length() == 2 {
            parsed
          } else {
            default_val
          }
        }
        _ => default_val
      }
    None => default_val
  }
}

///|
fn parse_calendar_cell_size_item(j : Json) -> CalendarCellSize {
  match j {
    Number(n, ..) => CalendarCellSize::Px(n)
    String("auto") => CalendarCellSize::Auto
    _ => CalendarCellSize::Auto
  }
}

///|
fn parse_calendar_range(j : Json, default_val : Array[String]) -> Array[String] {
  match j_field(j, "range") {
    Some(String(s)) => [s]
    Some(Number(n, ..)) => ["\{n.to_int()}"]
    Some(Array(arr)) => arr.map(json_to_stringish_empty)
    _ => default_val
  }
}

///|
fn parse_calendar_split_line(j : Json) -> CalendarSplitLineOption {
  let base = CalendarSplitLineOption::default()
  let split_line = j_field_or_self(j, "splitLine")
  let line_style = j_field_or_self(split_line, "lineStyle")
  {
    show: j_bool(split_line, "show", base.show),
    color: j_string(line_style, "color", base.color),
    width: j_number(line_style, "width", base.width),
  }
}

///|
fn parse_calendar_item_style(j : Json) -> CalendarItemStyleOption {
  let base = CalendarItemStyleOption::default()
  let item_style = j_field_or_self(j, "itemStyle")
  {
    color: j_string(item_style, "color", base.color),
    border_width: j_number(item_style, "borderWidth", base.border_width),
    border_color: j_string(item_style, "borderColor", base.border_color),
  }
}

///|
fn parse_calendar_day_label(j : Json) -> CalendarDayLabelOption {
  let base = CalendarDayLabelOption::default()
  let label = j_field_or_self(j, "dayLabel")
  {
    show: j_bool(label, "show", base.show),
    first_day: j_int(label, "firstDay", base.first_day),
    position: j_string(label, "position", base.position),
    margin: j_string_or_number(label, "margin", base.margin),
    name_map: parse_name_map(label),
    color: j_string(label, "color", base.color),
    font_size: j_number(label, "fontSize", base.font_size),
    font_family: j_string(label, "fontFamily", base.font_family),
    font_weight: j_string(label, "fontWeight", base.font_weight),
    silent: j_bool(label, "silent", base.silent),
  }
}

///|
fn parse_calendar_month_label(j : Json) -> CalendarMonthLabelOption {
  let base = CalendarMonthLabelOption::default()
  let label = j_field_or_self(j, "monthLabel")
  {
    show: j_bool(label, "show", base.show),
    position: j_string(label, "position", base.position),
    margin: j_number(label, "margin", base.margin),
    align: j_string(label, "align", base.align),
    formatter: j_string_opt(label, "formatter"),
    name_map: parse_name_map(label),
    color: j_string(label, "color", base.color),
    font_size: j_number(label, "fontSize", base.font_size),
    font_family: j_string(label, "fontFamily", base.font_family),
    font_weight: j_string(label, "fontWeight", base.font_weight),
    silent: j_bool(label, "silent", base.silent),
  }
}

///|
fn parse_calendar_year_label(j : Json) -> CalendarYearLabelOption {
  let base = CalendarYearLabelOption::default()
  let label = j_field_or_self(j, "yearLabel")
  {
    show: j_bool(label, "show", base.show),
    position: j_string_opt(label, "position"),
    margin: j_number(label, "margin", base.margin),
    formatter: j_string_opt(label, "formatter"),
    color: j_string(label, "color", base.color),
    font_size: j_number(label, "fontSize", base.font_size),
    font_family: j_string(label, "fontFamily", base.font_family),
    font_weight: j_string(label, "fontWeight", base.font_weight),
    silent: j_bool(label, "silent", base.silent),
  }
}

///|
fn parse_name_map(j : Json) -> Array[String]? {
  match j_field(j, "nameMap") {
    Some(Array(arr)) => Some(arr.map(json_to_stringish_empty))
    _ => None
  }
}

///|
/// Parse a visualMap option. Supports continuous visualMap.
/// Corresponds to echarts/src/component/visualMap/VisualMapModel.ts
fn parse_aria_option(j : Json) -> AriaOption {
  let base = AriaOption::default()
  let show_enabled = match j_field(j, "show") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  let enabled = match j_field(j, "enabled") {
    Some(True) => true
    Some(False) => false
    _ => show_enabled.unwrap_or(base.enabled)
  }
  let label = j_field_or_self(j, "label")
  let label_enabled = match j_field(label, "enabled") {
    Some(True) => true
    Some(False) => false
    _ => base.label_enabled
  }
  let description = match j_field(label, "description") {
    Some(String(s)) => Some(s)
    _ => j_string_opt(j, "description")
  }
  let general = j_field_or_self(label, "general")
  let series = j_field_or_self(label, "series")
  let data = j_field_or_self(label, "data")
  let series_single = j_field_or_self(series, "single")
  let series_multiple = j_field_or_self(series, "multiple")
  let series_separator = j_field_or_self(series_multiple, "separator")
  let data_separator = j_field_or_self(data, "separator")
  {
    enabled,
    label_enabled,
    description,
    general_with_title: j_string(general, "withTitle", base.general_with_title),
    general_without_title: j_string(
      general,
      "withoutTitle",
      base.general_without_title,
    ),
    series_max_count: j_int(series, "maxCount", base.series_max_count),
    series_single_prefix: j_string(
      series_single,
      "prefix",
      base.series_single_prefix,
    ),
    series_single_with_name: j_string(
      series_single,
      "withName",
      base.series_single_with_name,
    ),
    series_single_without_name: j_string(
      series_single,
      "withoutName",
      base.series_single_without_name,
    ),
    series_multiple_prefix: j_string(
      series_multiple,
      "prefix",
      base.series_multiple_prefix,
    ),
    series_multiple_with_name: j_string(
      series_multiple,
      "withName",
      base.series_multiple_with_name,
    ),
    series_multiple_without_name: j_string(
      series_multiple,
      "withoutName",
      base.series_multiple_without_name,
    ),
    series_multiple_separator_middle: j_string(
      series_separator,
      "middle",
      base.series_multiple_separator_middle,
    ),
    series_multiple_separator_end: j_string(
      series_separator,
      "end",
      base.series_multiple_separator_end,
    ),
    data_max_count: j_int(data, "maxCount", base.data_max_count),
    data_all_data: j_string(data, "allData", base.data_all_data),
    data_partial_data: j_string(data, "partialData", base.data_partial_data),
    data_with_name: j_string(data, "withName", base.data_with_name),
    data_without_name: j_string(data, "withoutName", base.data_without_name),
    data_separator_middle: j_string(
      data_separator,
      "middle",
      base.data_separator_middle,
    ),
    data_separator_end: j_string(data_separator, "end", base.data_separator_end),
  }
}

///|
fn parse_symbol_repeat(j : Json, base : SeriesOption) -> (String?, Int?, Bool) {
  match j_field(j, "symbolRepeat") {
    Some(True) => (Some("true"), None, false)
    Some(False) => (Some("false"), None, false)
    Some(Number(n, ..)) => (Some("number"), Some(n.to_int()), false)
    Some(String(s)) =>
      if s == "fixed" {
        (Some("fixed"), None, true)
      } else {
        (Some(s), None, false)
      }
    _ =>
      (base.symbol_repeat, base.symbol_repeat_count, base.symbol_repeat_fixed)
  }
}

///|
fn parse_symbol_bounding_data(j : Json) -> SymbolBoundingData? {
  match j_field(j, "symbolBoundingData") {
    Some(Number(n, ..)) => Some(Single(n))
    Some(Array(arr)) => pair_symbol_bounding_data(arr)
    _ => None
  }
}

///|
fn parse_symbol_size_values(j : Json) -> Array[String]? {
  j_stringish_pair_opt(j, "symbolSize")
}

///|
fn parse_symbol_values(j : Json) -> Array[String]? {
  match j_field(j, "symbol") {
    Some(String(s)) => Some([s, s])
    Some(Array(arr)) => pair_strings_from_json(arr)
    _ => None
  }
}

///|
fn parse_symbol_offset(j : Json) -> Array[String]? {
  j_stringish_pair_opt(j, "symbolOffset")
}

///|
/// Parse a DataZoomOption from JSON.
///
/// <=> echarts/src/component/dataZoom/DataZoomModel.ts DataZoomOption
fn parse_data_zoom_option(j : Json) -> DataZoomOption {
  let base = DataZoomOption::default()
  let start = j_number(j, "start", base.start)
  let end = j_number(j, "end", base.end)
  let start_value = interaction_stringish_opt(j, "startValue")
  let end_value = interaction_stringish_opt(j, "endValue")
  { start, end, start_value, end_value }
}

///|

///|
fn parse_visual_map(j : Json) -> VisualMapOption {
  let base = VisualMapOption::default()
  let controller_inrange = j_field(j, "controller")
    .map(ctrl => j_field_or_self(ctrl, "inRange"))
    .map(parse_visual_map_in_range)
  let pieces = match j_field(j, "pieces") {
    Some(Array(arr)) => arr.map(parse_visual_map_piece)
    _ =>
      match j_field(j, "splitList") {
        Some(Array(arr)) => arr.map(parse_visual_map_piece)
        _ => base.pieces
      }
  }
  {
    map_type: j_string_opt(j, "type"),
    min: j_number(j, "min", base.min),
    max: j_number(j, "max", base.max),
    series_index: match j_field(j, "seriesIndex") {
      Some(Number(n, ..)) => Some(n.to_int())
      _ => None
    },
    dimension: j_int(j, "dimension", base.dimension),
    color: j_stringish_array(j, "color", base.color),
    text: j_stringish_array(j, "text", base.text),
    in_range: parse_visual_map_in_range(j_field_or_self(j, "inRange")),
    out_of_range: match j_field(j, "outOfRange") {
      Some(value) => Some(parse_visual_map_in_range(value))
      None => base.out_of_range
    },
    text_style: match j_field(j, "textStyle") {
      Some(value) => Some(parse_chart_text_style_option(value))
      None => base.text_style
    },
    pieces,
    categories: j_stringish_array(j, "categories", base.categories),
    split_number: j_int(j, "splitNumber", base.split_number),
    selected: parse_visual_map_selected(j),
    range: match j_field(j, "range") {
      Some(Array(arr)) => {
        let r : Array[Double] = []
        for v in arr {
          match v {
            Number(n, ..) => r.push(n)
            _ => ()
          }
        }
        r
      }
      _ => base.range
    },
    selected_mode: match j_field(j, "selectedMode") {
      Some(True) => "multiple"
      Some(False) => ""
      Some(String(s)) => s
      _ => base.selected_mode
    },
    show_label: match j_field(j, "showLabel") {
      Some(True) => Some(true)
      Some(False) => Some(false)
      _ => base.show_label
    },
    item_gap: j_number(j, "itemGap", base.item_gap),
    inverse: j_bool(j, "inverse", base.inverse),
    align: j_string(j, "align", base.align),
    item_symbol: j_string(j, "itemSymbol", base.item_symbol),
    min_open: j_bool(j, "minOpen", base.min_open),
    max_open: j_bool(j, "maxOpen", base.max_open),
    precision: j_int(j, "precision", base.precision),
    orient: match j_field(j, "orient") {
      Some(String(s)) => s
      _ => base.orient
    },
    left: j_string_or_number_as_string_opt(j, "left", base.left),
    right: j_string_or_number_as_string_opt(j, "right", base.right),
    top: j_string_or_number_as_string_opt(j, "top", base.top),
    bottom: j_string_or_number_as_string_opt(j, "bottom", base.bottom),
    show: j_bool(j, "show", base.show),
    item_width: match j_field(j, "itemWidth") {
      Some(Number(n, ..)) => Some(n)
      _ => base.item_width
    },
    item_height: match j_field(j, "itemHeight") {
      Some(Number(n, ..)) => Some(n)
      _ => base.item_height
    },
    controller_in_range: controller_inrange,
  }
}

///|
fn parse_visual_map_piece(j : Json) -> VisualMapPieceOption {
  let base = VisualMapPieceOption::default()
  match j {
    Object(_) => {
      let min = match j_field(j, "min") {
        Some(Number(n, ..)) => Some(n)
        _ =>
          match j_field(j, "start") {
            Some(Number(n, ..)) => Some(n)
            _ => base.min
          }
      }
      let max = match j_field(j, "max") {
        Some(Number(n, ..)) => Some(n)
        _ =>
          match j_field(j, "end") {
            Some(Number(n, ..)) => Some(n)
            _ => base.max
          }
      }
      {
        min,
        max,
        gt: j_number_opt(j, "gt"),
        gte: j_number_opt(j, "gte"),
        lt: j_number_opt(j, "lt"),
        lte: j_number_opt(j, "lte"),
        value: match j_field(j, "value") {
          Some(String(s)) => Some(s)
          Some(Number(n, ..)) => Some("\{n}")
          _ => base.value
        },
        label: j_string_opt(j, "label"),
        color: j_string_opt(j, "color"),
        symbol: j_string_opt(j, "symbol"),
      }
    }
    String(s) => { ..base, value: Some(s) }
    Number(n, ..) => { ..base, value: Some("\{n}") }
    _ => base
  }
}

///|
fn parse_visual_map_selected(j : Json) -> Array[VisualMapSelection] {
  match j_field(j, "selected") {
    Some(Object(map)) => {
      let result : Array[VisualMapSelection] = []
      for key, value in map {
        let selected = match value {
          False => false
          _ => true
        }
        result.push({ key, selected })
      }
      result
    }
    _ => []
  }
}

///|
fn parse_visual_map_in_range(j : Json) -> VisualMapInRange {
  let base = VisualMapInRange::default()
  {
    color: j_stringish_array(j, "color", base.color),
    symbol_size: parse_number_pair(j_field(j, "symbolSize")),
    opacity: parse_number_pair(j_field(j, "opacity")),
  }
}

///|
fn parse_number_pair(j : Json?) -> Array[Double] {
  match j {
    Some(Array(arr)) => {
      let result : Array[Double] = []
      let mut i = 0
      while i < arr.length() && i < 2 {
        result.push(json_number_or_zero(arr[i]))
        i += 1
      }
      result
    }
    Some(Number(n, ..)) => [n, n]
    _ => []
  }
}

///|
fn[T] j_parse_optional(j : Json, key : String, parse_one : (Json) -> T) -> T? {
  j_field(j, key).map(parse_one)
}

///|
fn[T] j_parse_array(
  j : Json,
  key : String,
  parse_one : (Json) -> T,
  default_val : Array[T],
) -> Array[T] {
  match j_field(j, key) {
    Some(Array(arr)) => arr.map(parse_one)
    _ => default_val
  }
}

///|
fn[T] j_parse_one_or_many(
  j : Json,
  key : String,
  parse_one : (Json) -> T,
  default_val : Array[T],
) -> Array[T] {
  match j_field(j, key) {
    Some(value) =>
      match value {
        Array(arr) => arr.map(parse_one)
        Object(_) => [parse_one(value)]
        _ => default_val
      }
    None => default_val
  }
}

///|
fn j_field_or_self(j : Json, key : String) -> Json {
  match j_field(j, key) {
    Some(value) => value
    None => j
  }
}

///|
fn j_string_or_number(j : Json, key : String, default_val : String) -> String {
  match j_field(j, key) {
    Some(String(s)) => s
    Some(Number(n, ..)) => "\{n}"
    _ => default_val
  }
}

///|
fn j_string_or_number_as_string_opt(
  j : Json,
  key : String,
  default_val : String?,
) -> String? {
  match j_field(j, key) {
    Some(String(s)) => Some(s)
    Some(Number(n, ..)) => Some("\{n}")
    _ => default_val
  }
}

///|
fn j_string_array_lossy(
  j : Json,
  key : String,
  default_val : Array[String],
) -> Array[String] {
  match j_field(j, key) {
    Some(Array(arr)) =>
      arr.map(fn(item) {
        match item {
          String(s) => s
          _ => item.to_string()
        }
      })
    _ => default_val
  }
}

///|
fn j_stringish_array(
  j : Json,
  key : String,
  default_val : Array[String],
) -> Array[String] {
  match j_field(j, key) {
    Some(Array(arr)) => arr.map(json_to_stringish_empty)
    Some(String(s)) => [s]
    Some(Number(n, ..)) => ["\{n}"]
    _ => default_val
  }
}

///|
fn j_stringish_pair_opt(j : Json, key : String) -> Array[String]? {
  match j_field(j, key) {
    Some(String(s)) => Some([s, s])
    Some(Number(n, ..)) => {
      let value = "\{n}"
      Some([value, value])
    }
    Some(Array(arr)) => pair_strings_from_json(arr)
    _ => None
  }
}

///|
fn pair_strings_from_json(arr : Array[Json]) -> Array[String]? {
  match arr {
    [] => None
    [first] => {
      let value = json_to_stringish_zero(first)
      Some([value, value])
    }
    [first, second, ..] =>
      Some([json_to_stringish_zero(first), json_to_stringish_zero(second)])
  }
}

///|
fn pair_number_arrays_from_json(arr : Array[Json]) -> Array[Array[Double]]? {
  match arr {
    [first, second, ..] =>
      match first {
        Array(first_arr) =>
          match second {
            Array(second_arr) =>
              Some([
                first_arr.map(json_number_or_zero),
                second_arr.map(json_number_or_zero),
              ])
            _ => None
          }
        _ => None
      }
    _ => None
  }
}

///|
fn pair_symbol_bounding_data(arr : Array[Json]) -> SymbolBoundingData? {
  match arr {
    [first, second, ..] =>
      Some(Pair(json_number_or_zero(first), json_number_or_zero(second)))
    _ => None
  }
}

///|
fn empty_data_item_with_coords(coords : Array[Array[Double]]) -> DataItem {
  {
    value: DataValue::Null,
    raw_value_parts: None,
    raw_item: None,
    id: None,
    name: None,
    depth: None,
    source: None,
    target: None,
    symbol: None,
    coords: Some(coords),
    from_name: None,
    to_name: None,
    cursor: None,
    selected: None,
    silent: None,
    label: None,
    item_style: None,
    states: GeoStatesOption::default(),
    children: [],
    collapsed: None,
    title_offset_center: None,
    detail_offset_center: None,
    highlighted: None,
  }
}

///|
fn parse_lines_flat_data(arr : Array[Json]) -> Array[DataItem] {
  let result : Array[DataItem] = []
  let mut i = 0
  while i < arr.length() {
    let count = match arr[i] {
      Number(n, ..) => n.to_int()
      _ => 0
    }
    i += 1
    if count <= 0 {
      continue
    }
    let coords : Array[Array[Double]] = []
    let mut k = 0
    while k < count && i + 1 < arr.length() {
      coords.push([json_number_or_zero(arr[i]), json_number_or_zero(arr[i + 1])])
      i += 2
      k += 1
    }
    if coords.length() == count {
      result.push(empty_data_item_with_coords(coords))
    } else {
      return result
    }
  }
  result
}

///|
fn parse_data_object(j : Json, value : DataValue) -> DataItem {
  let raw_value_parts = match j_field(j, "value") {
    Some(Array(arr)) => Some(arr)
    _ => None
  }
  let id = j_string_or_number_as_string_opt(j, "id", None)
  let name = j_string_opt(j, "name")
  let depth = match j_field(j, "depth") {
    Some(Number(n, ..)) => Some(n.to_int())
    _ => None
  }
  let source = j_string_or_number_as_string_opt(j, "source", None)
  let target = j_string_or_number_as_string_opt(j, "target", None)
  let symbol = j_string_opt(j, "symbol")
  let coords = parse_data_coords(j)
  let from_name = j_string_opt(j, "fromName")
  let to_name = j_string_opt(j, "toName")
  let cursor = j_string_opt(j, "cursor")
  let selected = match j_field(j, "selected") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  let silent = match j_field(j, "silent") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  let label = match j_field(j, "label") {
    Some(value) => Some(parse_geo_label_patch_option(value))
    None => None
  }
  let item_style = match j_field(j, "itemStyle") {
    Some(style) => Some(parse_geo_item_style_patch_option(style))
    None => None
  }
  let children = j_parse_array(j, "children", parse_data_item, [])
  let collapsed = match j_field(j, "collapsed") {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
  // Gauge per-item title/detail offsetCenter
  let title_offset_center = match j_field(j, "title") {
    Some(t) =>
      match j_field(t, "offsetCenter") {
        Some(Array(arr)) =>
          Some(
            arr.map(fn(x) {
              match x {
                String(s) => s
                Number(n, ..) => "\{n}"
                _ => "0"
              }
            }),
          )
        _ => None
      }
    None => None
  }
  let detail_offset_center = match j_field(j, "detail") {
    Some(d) =>
      match j_field(d, "offsetCenter") {
        Some(Array(arr)) =>
          Some(
            arr.map(fn(x) {
              match x {
                String(s) => s
                Number(n, ..) => "\{n}"
                _ => "0"
              }
            }),
          )
        _ => None
      }
    None => None
  }
  {
    value,
    raw_value_parts,
    raw_item: Some(j),
    id,
    name,
    depth,
    source,
    target,
    symbol,
    coords,
    from_name,
    to_name,
    cursor,
    selected,
    silent,
    label,
    item_style,
    states: parse_geo_states_option(j),
    children,
    collapsed,
    title_offset_center,
    detail_offset_center,
    highlighted: None,
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
fn json_to_stringish_zero(j : Json) -> String {
  match j {
    String(s) => s
    Number(n, ..) => "\{n}"
    _ => "0"
  }
}

///|
fn json_to_stringish_empty(j : Json) -> String {
  match j {
    String(s) => s
    Number(n, ..) => "\{n}"
    _ => ""
  }
}

///|
/// Get a field from a JSON object.
fn j_field(j : Json, key : String) -> Json? {
  match j {
    Object(map) => map.get(key)
    _ => None
  }
}

///|
fn j_number(j : Json, key : String, default_val : Double) -> Double {
  match j_field(j, key) {
    Some(Number(n, ..)) => n
    _ => default_val
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
fn j_string(j : Json, key : String, default_val : String) -> String {
  match j_field(j, key) {
    Some(String(s)) => s
    _ => default_val
  }
}

///|
fn j_string_opt(j : Json, key : String) -> String? {
  match j_field(j, key) {
    Some(String(s)) => Some(s)
    _ => None
  }
}

///|
fn j_color_opt(j : Json, key : String) -> String? {
  match j_field(j, key) {
    Some(String(s)) => Some(s)
    Some(Object(_)) => j_linear_gradient_spec(j_field(j, key))
    _ => None
  }
}

///|
fn j_linear_gradient_spec(value : Json?) -> String? {
  match value {
    Some(Object(_)) => {
      let jv = value.unwrap()
      let gradient_type = j_string(jv, "type", "")
      if gradient_type != "linear" {
        return None
      }
      let x = j_number(jv, "x", 0.0)
      let y = j_number(jv, "y", 0.0)
      let x2 = j_number(jv, "x2", 0.0)
      let y2 = j_number(jv, "y2", 1.0)
      let stops = j_linear_gradient_color_stops(jv)
      if stops.length() == 0 {
        None
      } else {
        let stops_str = stops.join(";")
        Some(
          "__linear_gradient__|x=\{x}|y=\{y}|x2=\{x2}|y2=\{y2}|stops=\{stops_str}",
        )
      }
    }
    _ => None
  }
}

///|
fn j_linear_gradient_color_stops(j : Json) -> Array[String] {
  let stops : Array[String] = []
  match j_field(j, "colorStops") {
    Some(Array(arr)) =>
      for stop in arr {
        match stop {
          Object(_) => {
            let offset = j_number_opt(stop, "offset")
            let color = j_color_literal(stop, "color")
            match (offset, color) {
              (Some(off), Some(c)) => stops.push("\{off}:\{c}")
              _ => ()
            }
          }
          Array([Number(offset, ..), String(color)]) =>
            stops.push("\{offset}:\{color}")
          _ => ()
        }
      }
    _ => ()
  }
  stops
}

///|
fn j_color_literal(j : Json, key : String) -> String? {
  match j_field(j, key) {
    Some(String(s)) => Some(s)
    _ => None
  }
}

///|
fn j_bool(j : Json, key : String, default_val : Bool) -> Bool {
  match j_field(j, key) {
    Some(True) => true
    Some(False) => false
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

///|
fn j_int(j : Json, key : String, default_val : Int) -> Int {
  match j_field(j, key) {
    Some(Number(n, ..)) => n.to_int()
    _ => default_val
  }
}
