///|
/// <=> echarts/src/core/echarts.ts:setOption
/// <=> echarts/src/core/echarts.ts:dispatchAction
/// <=> echarts/src/model/OptionManager.ts
/// Repo-specific adapter that normalizes a JSON interaction envelope into
/// rerenderable option state before the static MoonBit pipeline runs.
pub fn parse_render_input(
  json_str : String,
) -> @option.ChartOption raise @json.ParseError {
  let root = @json.parse(json_str)
  parse_render_input_json(root)
}

///|
/// <=> echarts/src/core/echarts.ts:setOption
/// <=> echarts/src/model/OptionManager.ts
pub fn parse_render_input_json(root : Json) -> @option.ChartOption {
  let has_envelope = interaction_option_json(root) is Some(_)
  let base_json = interaction_option_json(root).unwrap_or(root)
  let base_opt = @option.parse_json(base_json)
  let with_outer = if has_envelope {
    @option.apply_render_input_root_overrides(base_opt, root)
  } else {
    base_opt
  }
  let with_patch = @option.apply_interaction_option_patch_json(
    with_outer,
    interaction_option_patch_json(root),
  )
  let with_state = @option.apply_interaction_state_json(
    with_patch,
    interaction_state_json(root),
  )
  @option.apply_interaction_dispatch_actions_json(
    with_state,
    interaction_dispatch_actions_json(root),
  )
}

///|
/// <=> echarts/src/model/OptionManager.ts
fn interaction_option_patch_json(root : Json) -> Json? {
  match root {
    Object(map) =>
      match map.get("interaction") {
        Some(Object(interaction_map)) =>
          match interaction_map.get("optionPatch") {
            Some(value) =>
              match value {
                Object(_) => Some(value)
                _ => None
              }
            _ => None
          }
        _ => None
      }
    _ => None
  }
}

///|
/// <=> echarts/src/model/OptionManager.ts
fn interaction_option_json(root : Json) -> Json? {
  match root {
    Object(map) =>
      match map.get("option") {
        Some(value) =>
          match value {
            Object(_) => Some(value)
            _ => None
          }
        _ => None
      }
    _ => None
  }
}

///|
/// <=> echarts/src/core/echarts.ts:dispatchAction
fn interaction_state_json(root : Json) -> Json? {
  match root {
    Object(map) =>
      match map.get("interaction") {
        Some(Object(interaction_map)) =>
          match interaction_map.get("state") {
            Some(value) =>
              match value {
                Object(_) => Some(value)
                _ => None
              }
            _ => None
          }
        _ => None
      }
    _ => None
  }
}

///|
/// <=> echarts/src/core/echarts.ts:dispatchAction
/// Looks for dispatchActions at root level or nested under "interaction".
fn interaction_dispatch_actions_json(root : Json) -> Json? {
  match root {
    Object(map) => {
      // Primary: top-level "dispatchActions" key
      match map.get("dispatchActions") {
        Some(Array(_) as v) => return Some(v)
        _ => ()
      }
      // Fallback: nested under "interaction.dispatchActions"
      match map.get("interaction") {
        Some(Object(interaction_map)) =>
          match interaction_map.get("dispatchActions") {
            Some(Array(_) as v) => Some(v)
            _ => None
          }
        _ => None
      }
    }
    _ => None
  }
}
