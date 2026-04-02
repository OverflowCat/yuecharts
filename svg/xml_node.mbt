// Corresponds to: zrender/src/svg/core.ts
// Lightweight XML node builder plus direct String / UTF-8 / UTF-16LE serializers.

///|
pub struct XmlAttr {
  name : String
  value : String?
}

///|
pub fn XmlAttr::new(name : String, value : String) -> XmlAttr {
  { name, value: Some(value) }
}

///|
pub fn XmlAttr::flag(name : String) -> XmlAttr {
  { name, value: None }
}

///|
pub enum XmlText {
  Escaped(String)
  Raw(String)
}

///|
pub fn XmlText::escaped(content : String) -> XmlText {
  Escaped(content)
}

///|
pub fn XmlText::raw(content : String) -> XmlText {
  Raw(content)
}

///|
pub struct XmlElement {
  tag : String
  attrs : Array[XmlAttr]
  children : Array[XmlNode]
}

///|
pub fn XmlElement::new(
  tag : String,
  attrs : Array[XmlAttr],
  children : Array[XmlNode],
) -> XmlElement {
  { tag, attrs, children }
}

///|
pub enum XmlNode {
  Element(XmlElement)
  Text(XmlText)
}

///|
pub fn XmlNode::element(
  tag : String,
  attrs : Array[XmlAttr],
  children : Array[XmlNode],
) -> XmlNode {
  Element({ tag, attrs, children })
}

///|
pub fn XmlNode::empty(tag : String, attrs : Array[XmlAttr]) -> XmlNode {
  Element({ tag, attrs, children: [] })
}

///|
pub fn XmlNode::text_escaped(content : String) -> XmlNode {
  Text(Escaped(content))
}

///|
pub fn XmlNode::text_raw(content : String) -> XmlNode {
  Text(Raw(content))
}

///|
fn xml_children_inline(children : Array[XmlNode]) -> Bool {
  let mut i = 0
  while i < children.length() {
    match children[i] {
      Text(_) => ()
      _ => return false
    }
    i += 1
  }
  true
}

///|
fn xml_write_indent_string(
  buf : StringBuilder,
  depth : Int,
  indent_unit : String,
) -> Unit {
  let mut i = 0
  while i < depth {
    buf.write_string(indent_unit)
    i += 1
  }
}

///|
fn xml_write_indent_buffer(
  buf : @buffer.Buffer,
  depth : Int,
  indent_unit : String,
  utf16le : Bool,
) -> Unit {
  let mut i = 0
  while i < depth {
    if utf16le {
      buf.write_string_utf16le(indent_unit)
    } else {
      buf.write_string_utf8(indent_unit)
    }
    i += 1
  }
}

///|
fn xml_write_literal_buffer(
  buf : @buffer.Buffer,
  s : String,
  utf16le : Bool,
) -> Unit {
  if utf16le {
    buf.write_string_utf16le(s)
  } else {
    buf.write_string_utf8(s)
  }
}

///|
fn xml_escape_write_string(buf : StringBuilder, s : String) -> Unit {
  for c in s {
    match c {
      '&' => buf.write_string("&amp;")
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '"' => buf.write_string("&quot;")
      '\'' => buf.write_string("&#39;")
      _ => buf.write_char(c)
    }
  }
}

///|
fn xml_escape_write_buffer(
  buf : @buffer.Buffer,
  s : String,
  utf16le : Bool,
) -> Unit {
  for c in s {
    match c {
      '&' => xml_write_literal_buffer(buf, "&amp;", utf16le)
      '<' => xml_write_literal_buffer(buf, "&lt;", utf16le)
      '>' => xml_write_literal_buffer(buf, "&gt;", utf16le)
      '"' => xml_write_literal_buffer(buf, "&quot;", utf16le)
      '\'' => xml_write_literal_buffer(buf, "&#39;", utf16le)
      _ =>
        if utf16le {
          buf.write_char_utf16le(c)
        } else {
          buf.write_char_utf8(c)
        }
    }
  }
}

///|
pub fn xml_escape(s : String) -> String {
  let buf = StringBuilder::new()
  xml_escape_write_string(buf, s)
  buf.to_string()
}

///|
fn xml_write_attr_string(buf : StringBuilder, attr : XmlAttr) -> Unit {
  buf.write_char(' ')
  buf.write_string(attr.name)
  match attr.value {
    Some(value) => {
      buf.write_string("=\"")
      xml_escape_write_string(buf, value)
      buf.write_char('"')
    }
    None => ()
  }
}

///|
fn xml_write_attr_buffer(
  buf : @buffer.Buffer,
  attr : XmlAttr,
  utf16le : Bool,
) -> Unit {
  xml_write_literal_buffer(buf, " ", utf16le)
  xml_write_literal_buffer(buf, attr.name, utf16le)
  match attr.value {
    Some(value) => {
      xml_write_literal_buffer(buf, "=\"", utf16le)
      xml_escape_write_buffer(buf, value, utf16le)
      xml_write_literal_buffer(buf, "\"", utf16le)
    }
    None => ()
  }
}

///|
fn xml_write_text_string(buf : StringBuilder, text : XmlText) -> Unit {
  match text {
    Escaped(content) => xml_escape_write_string(buf, content)
    Raw(content) => buf.write_string(content)
  }
}

///|
fn xml_write_text_buffer(
  buf : @buffer.Buffer,
  text : XmlText,
  utf16le : Bool,
) -> Unit {
  match text {
    Escaped(content) => xml_escape_write_buffer(buf, content, utf16le)
    Raw(content) => xml_write_literal_buffer(buf, content, utf16le)
  }
}

///|
fn xml_write_node_string(
  buf : StringBuilder,
  node : XmlNode,
  pretty : Bool,
  indent_unit : String,
  depth : Int,
) -> Unit {
  match node {
    Text(text) => xml_write_text_string(buf, text)
    Element(element) => {
      buf.write_char('<')
      buf.write_string(element.tag)
      for attr in element.attrs {
        xml_write_attr_string(buf, attr)
      }
      if element.children.length() == 0 {
        buf.write_string("/>")
        return
      }
      buf.write_char('>')
      let inline_children = xml_children_inline(element.children)
      if pretty && !inline_children {
        buf.write_char('\n')
        let mut i = 0
        while i < element.children.length() {
          xml_write_indent_string(buf, depth + 1, indent_unit)
          xml_write_node_string(
            buf,
            element.children[i],
            pretty,
            indent_unit,
            depth + 1,
          )
          buf.write_char('\n')
          i += 1
        }
        xml_write_indent_string(buf, depth, indent_unit)
      } else {
        for child in element.children {
          xml_write_node_string(buf, child, pretty, indent_unit, depth + 1)
        }
      }
      buf.write_string("</")
      buf.write_string(element.tag)
      buf.write_char('>')
    }
  }
}

///|
fn xml_write_node_buffer(
  buf : @buffer.Buffer,
  node : XmlNode,
  pretty : Bool,
  indent_unit : String,
  depth : Int,
  utf16le : Bool,
) -> Unit {
  match node {
    Text(text) => xml_write_text_buffer(buf, text, utf16le)
    Element(element) => {
      xml_write_literal_buffer(buf, "<", utf16le)
      xml_write_literal_buffer(buf, element.tag, utf16le)
      for attr in element.attrs {
        xml_write_attr_buffer(buf, attr, utf16le)
      }
      if element.children.length() == 0 {
        xml_write_literal_buffer(buf, "/>", utf16le)
        return
      }
      xml_write_literal_buffer(buf, ">", utf16le)
      let inline_children = xml_children_inline(element.children)
      if pretty && !inline_children {
        xml_write_literal_buffer(buf, "\n", utf16le)
        let mut i = 0
        while i < element.children.length() {
          xml_write_indent_buffer(buf, depth + 1, indent_unit, utf16le)
          xml_write_node_buffer(
            buf,
            element.children[i],
            pretty,
            indent_unit,
            depth + 1,
            utf16le,
          )
          xml_write_literal_buffer(buf, "\n", utf16le)
          i += 1
        }
        xml_write_indent_buffer(buf, depth, indent_unit, utf16le)
      } else {
        for child in element.children {
          xml_write_node_buffer(
            buf,
            child,
            pretty,
            indent_unit,
            depth + 1,
            utf16le,
          )
        }
      }
      xml_write_literal_buffer(buf, "</", utf16le)
      xml_write_literal_buffer(buf, element.tag, utf16le)
      xml_write_literal_buffer(buf, ">", utf16le)
    }
  }
}

///|
pub fn xml_to_string(node : XmlNode) -> String {
  let buf = StringBuilder::new()
  xml_write_node_string(buf, node, false, "  ", 0)
  buf.to_string()
}

///|
pub fn xml_to_pretty_string(node : XmlNode, indent_unit : String) -> String {
  let buf = StringBuilder::new()
  xml_write_node_string(buf, node, true, indent_unit, 0)
  buf.to_string()
}

///|
pub fn xml_to_utf8(node : XmlNode) -> Bytes {
  let buf = @buffer.new()
  xml_write_node_buffer(buf, node, false, "  ", 0, false)
  buf.to_bytes()
}

///|
pub fn xml_to_pretty_utf8(node : XmlNode, indent_unit : String) -> Bytes {
  let buf = @buffer.new()
  xml_write_node_buffer(buf, node, true, indent_unit, 0, false)
  buf.to_bytes()
}

///|
pub fn xml_to_utf16le(node : XmlNode) -> Bytes {
  let buf = @buffer.new()
  xml_write_node_buffer(buf, node, false, "  ", 0, true)
  buf.to_bytes()
}

///|
pub fn xml_to_pretty_utf16le(node : XmlNode, indent_unit : String) -> Bytes {
  let buf = @buffer.new()
  xml_write_node_buffer(buf, node, true, indent_unit, 0, true)
  buf.to_bytes()
}
