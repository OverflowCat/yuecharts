// Corresponds to: echarts/src/component/matrix/MatrixView.ts
//                  echarts/src/component/matrix/install.ts

///|
pub fn render_matrix(
  opt : @option.ChartOption,
  matrix? : @coord.Matrix,
) -> Array[@graphic.Element] {
  guard matrix is Some(matrix) && opt.matrix.length() > 0 else { [] }
  let elems : Array[@graphic.Element] = []
  let model = opt.matrix[0]
  elems.push(matrix_rect_element(matrix.rect, model.background_style))
  matrix_append_cells(elems, matrix.corner_cells)
  matrix_append_cells(elems, matrix.body_cells)
  matrix_append_cells(elems, matrix.x_cells)
  matrix_append_cells(elems, matrix.y_cells)
  if model.x.show {
    elems.push(
      @graphic.Element::line_colored(
        matrix.body_rect.x,
        matrix.body_rect.y,
        matrix.body_rect.right(),
        matrix.body_rect.y,
        model.x.divider_line_style.color,
        model.x.divider_line_style.width,
      ),
    )
  }
  if model.y.show {
    elems.push(
      @graphic.Element::line_colored(
        matrix.body_rect.x,
        matrix.body_rect.y,
        matrix.body_rect.x,
        matrix.body_rect.bottom(),
        model.y.divider_line_style.color,
        model.y.divider_line_style.width,
      ),
    )
  }
  elems
}

///|
fn matrix_append_cells(
  elems : Array[@graphic.Element],
  cells : Array[@coord.MatrixCell],
) -> Unit {
  let mut i = 0
  while i < cells.length() {
    let cell = cells[i]
    elems.push(matrix_rect_element(cell.bbox, cell.item_style))
    if cell.label.show {
      match cell.value {
        Some(value) if value != "" =>
          elems.push(
            @graphic.Element::text_custom(
              cell.bbox.center_x(),
              cell.bbox.center_y(),
              value,
              @graphic.TextAnchor::Middle,
              @graphic.TextBaseline::Central,
              cell.label.color,
              cell.label.font_size,
              cell.label.font_family,
              cell.label.font_weight,
            ),
          )
        _ => ()
      }
    }
    i += 1
  }
}

///|
fn matrix_rect_element(
  bbox : @graphic.BBox,
  style : @option.MatrixItemStyleOption,
) -> @graphic.Element {
  if style.color == "none" {
    @graphic.Element::rect_outlined(
      bbox.x,
      bbox.y,
      bbox.width,
      bbox.height,
      style.border_color,
      style.border_width,
    )
  } else {
    @graphic.Element::rect_fill_stroke(
      bbox.x,
      bbox.y,
      bbox.width,
      bbox.height,
      style.color,
      style.border_color,
      style.border_width,
    )
  }
}
