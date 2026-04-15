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
fn StringBuilder::write_xml_indent(
  self : Self,
  depth : Int,
  indent_unit : String,
) -> Unit {
  let mut i = 0
  while i < depth {
    self.write_string(indent_unit)
    i += 1
  }
}

///|
fn @buffer.Buffer::write_xml_indent(
  self : Self,
  depth : Int,
  indent_unit : String,
  utf16le : Bool,
) -> Unit {
  let mut i = 0
  while i < depth {
    self.write_xml_literal(indent_unit, utf16le)
    i += 1
  }
}

///|
fn @buffer.Buffer::write_xml_literal(
  self : Self,
  s : String,
  utf16le : Bool,
) -> Unit {
  if utf16le {
    self.write_string_utf16le(s)
  } else {
    self.write_string_utf8(s)
  }
}

///|
fn StringBuilder::write_xml_escaped(self : Self, s : String) -> Unit {
  for c in s {
    match c {
      '&' => self.write_string("&amp;")
      '<' => self.write_string("&lt;")
      '>' => self.write_string("&gt;")
      '"' => self.write_string("&quot;")
      '\'' => self.write_string("&#39;")
      _ => self.write_char(c)
    }
  }
}

///|
fn @buffer.Buffer::write_xml_escaped(
  self : Self,
  s : String,
  utf16le : Bool,
) -> Unit {
  for c in s {
    match c {
      '&' => self.write_xml_literal("&amp;", utf16le)
      '<' => self.write_xml_literal("&lt;", utf16le)
      '>' => self.write_xml_literal("&gt;", utf16le)
      '"' => self.write_xml_literal("&quot;", utf16le)
      '\'' => self.write_xml_literal("&#39;", utf16le)
      _ =>
        if utf16le {
          self.write_char_utf16le(c)
        } else {
          self.write_char_utf8(c)
        }
    }
  }
}

///|
fn String::xml_escape(self : Self) -> String {
  let buf = StringBuilder::new()
  buf.write_xml_escaped(self)
  buf.to_string()
}

///|
pub fn xml_escape(s : String) -> String {
  s.xml_escape()
}

///|
fn XmlAttr::write_to_string(self : Self, buf : StringBuilder) -> Unit {
  buf.write_char(' ')
  buf.write_string(self.name)
  match self.value {
    Some(value) => {
      buf.write_string("=\"")
      buf.write_xml_escaped(value)
      buf.write_char('"')
    }
    None => ()
  }
}

///|
fn XmlAttr::write_to_buffer(
  self : Self,
  buf : @buffer.Buffer,
  utf16le : Bool,
) -> Unit {
  buf.write_xml_literal(" ", utf16le)
  buf.write_xml_literal(self.name, utf16le)
  match self.value {
    Some(value) => {
      buf.write_xml_literal("=\"", utf16le)
      buf.write_xml_escaped(value, utf16le)
      buf.write_xml_literal("\"", utf16le)
    }
    None => ()
  }
}

///|
fn XmlText::write_to_string(self : Self, buf : StringBuilder) -> Unit {
  match self {
    Escaped(content) => buf.write_xml_escaped(content)
    Raw(content) => buf.write_string(content)
  }
}

///|
fn XmlText::write_to_buffer(
  self : Self,
  buf : @buffer.Buffer,
  utf16le : Bool,
) -> Unit {
  match self {
    Escaped(content) => buf.write_xml_escaped(content, utf16le)
    Raw(content) => buf.write_xml_literal(content, utf16le)
  }
}

///|
fn XmlNode::children_inline(children : Array[XmlNode]) -> Bool {
  let mut i = 0
  for i, _ in children {
    match children[i] {
      Text(_) => ()
      _ => return false
    }
  }
  true
}

///|
fn XmlNode::write_to_string(
  self : Self,
  buf : StringBuilder,
  pretty : Bool,
  indent_unit : String,
  depth : Int,
) -> Unit {
  match self {
    Text(text) => text.write_to_string(buf)
    Element(element) => {
      buf.write_char('<')
      buf.write_string(element.tag)
      for attr in element.attrs {
        attr.write_to_string(buf)
      }
      if element.children.length() == 0 {
        buf.write_string("/>")
        return
      }
      buf.write_char('>')
      let inline_children = XmlNode::children_inline(element.children)
      if pretty && !inline_children {
        buf.write_char('\n')
        let mut i = 0
        for i, _ in element.children {
          buf.write_xml_indent(depth + 1, indent_unit)
          element.children[i].write_to_string(
            buf,
            pretty,
            indent_unit,
            depth + 1,
          )
          buf.write_char('\n')
        }
        buf.write_xml_indent(depth, indent_unit)
      } else {
        for child in element.children {
          child.write_to_string(buf, pretty, indent_unit, depth + 1)
        }
      }
      buf.write_string("</")
      buf.write_string(element.tag)
      buf.write_char('>')
    }
  }
}

///|
fn XmlNode::write_to_buffer(
  self : Self,
  buf : @buffer.Buffer,
  pretty : Bool,
  indent_unit : String,
  depth : Int,
  utf16le : Bool,
) -> Unit {
  match self {
    Text(text) => text.write_to_buffer(buf, utf16le)
    Element(element) => {
      buf.write_xml_literal("<", utf16le)
      buf.write_xml_literal(element.tag, utf16le)
      for attr in element.attrs {
        attr.write_to_buffer(buf, utf16le)
      }
      if element.children.length() == 0 {
        buf.write_xml_literal("/>", utf16le)
        return
      }
      buf.write_xml_literal(">", utf16le)
      let inline_children = XmlNode::children_inline(element.children)
      if pretty && !inline_children {
        buf.write_xml_literal("\n", utf16le)
        for i, _ in element.children {
          buf.write_xml_indent(depth + 1, indent_unit, utf16le)
          element.children[i].write_to_buffer(
            buf,
            pretty,
            indent_unit,
            depth + 1,
            utf16le,
          )
          buf.write_xml_literal("\n", utf16le)
        }
        buf.write_xml_indent(depth, indent_unit, utf16le)
      } else {
        for child in element.children {
          child.write_to_buffer(buf, pretty, indent_unit, depth + 1, utf16le)
        }
      }
      buf.write_xml_literal("</", utf16le)
      buf.write_xml_literal(element.tag, utf16le)
      buf.write_xml_literal(">", utf16le)
    }
  }
}

///|
pub fn XmlNode::to_string(self : Self) -> String {
  let buf = StringBuilder::new()
  self.write_to_string(buf, false, "  ", 0)
  buf.to_string()
}

///|
pub fn XmlNode::to_pretty_string(self : Self, indent_unit : String) -> String {
  let buf = StringBuilder::new()
  self.write_to_string(buf, true, indent_unit, 0)
  buf.to_string()
}

///|
pub fn XmlNode::to_utf8(self : Self) -> Bytes {
  let buf = @buffer.new()
  self.write_to_buffer(buf, false, "  ", 0, false)
  buf.to_bytes()
}

///|
pub fn XmlNode::to_pretty_utf8(self : Self, indent_unit : String) -> Bytes {
  let buf = @buffer.new()
  self.write_to_buffer(buf, true, indent_unit, 0, false)
  buf.to_bytes()
}

///|
pub fn XmlNode::to_utf16le(self : Self) -> Bytes {
  let buf = @buffer.new()
  self.write_to_buffer(buf, false, "  ", 0, true)
  buf.to_bytes()
}

///|
pub fn XmlNode::to_pretty_utf16le(self : Self, indent_unit : String) -> Bytes {
  let buf = @buffer.new()
  self.write_to_buffer(buf, true, indent_unit, 0, true)
  buf.to_bytes()
}

///|
pub fn xml_to_string(node : XmlNode) -> String {
  node.to_string()
}

///|
pub fn xml_to_pretty_string(node : XmlNode, indent_unit : String) -> String {
  node.to_pretty_string(indent_unit)
}

///|
pub fn xml_to_utf8(node : XmlNode) -> Bytes {
  node.to_utf8()
}

///|
pub fn xml_to_pretty_utf8(node : XmlNode, indent_unit : String) -> Bytes {
  node.to_pretty_utf8(indent_unit)
}

///|
pub fn xml_to_utf16le(node : XmlNode) -> Bytes {
  node.to_utf16le()
}

///|
pub fn xml_to_pretty_utf16le(node : XmlNode, indent_unit : String) -> Bytes {
  node.to_pretty_utf16le(indent_unit)
}
