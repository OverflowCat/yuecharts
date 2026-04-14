// Corresponds to: echarts/src/component/visualMap/preprocessor.ts
//                  echarts/src/component/visualMap/PiecewiseModel.ts
// White-box tests for visualMap option parsing.

///|
test "visual map splitList and piece aliases normalize to pieces" {
  let vm = parse_visual_map(
    @json.parse(
      (
        #|{
        #|  "type": "piecewise",
        #|  "splitList": [
        #|    { "start": 0, "end": 10, "label": "Low" },
        #|    { "min": 10, "max": 20, "color": "#00aa00" }
        #|  ],
        #|  "selected": { "0": false },
        #|  "selectedMode": "single",
        #|  "text": ["High", "Low"],
        #|  "align": "right"
        #|}
      ),
    ),
  )
  assert_eq(vm.map_type, Some("piecewise"))
  assert_eq(vm.pieces.length(), 2)
  assert_eq(vm.pieces[0].min, Some(0.0))
  assert_eq(vm.pieces[0].max, Some(10.0))
  assert_eq(vm.pieces[0].label, Some("Low"))
  assert_eq(vm.pieces[1].min, Some(10.0))
  assert_eq(vm.pieces[1].max, Some(20.0))
  assert_eq(vm.pieces[1].color, Some("#00aa00"))
  assert_eq(vm.selected_mode, "single")
  assert_eq(vm.text, ["High", "Low"])
  assert_eq(vm.align, "right")
  assert_eq(vm.selected.length(), 1)
  assert_eq(vm.selected[0].key, "0")
  assert_true(!vm.selected[0].selected)
}
