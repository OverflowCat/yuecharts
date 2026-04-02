// Corresponds to: zrender/src/svg/core.ts
// White-box tests for svg/xml_node.mbt.

///|
test "xml builder escaped text and attrs" {
  let node = XmlNode::element(
    "text",
    [XmlAttr::new("data-v", "a&b"), XmlAttr::flag("focusable")],
    [XmlNode::text_escaped("<hi>")],
  )
  assert_eq(
    xml_to_string(node),
    "<text data-v=\"a&amp;b\" focusable>&lt;hi&gt;</text>",
  )
}

///|
test "xml builder raw text keeps cdata" {
  let node = XmlNode::element("style", [], [
    XmlNode::text_raw("<![CDATA[\n.a:hover { fill:red; }\n]]>"),
  ])
  assert_eq(
    xml_to_string(node),
    "<style><![CDATA[\n.a:hover { fill:red; }\n]]></style>",
  )
}

///|
test "xml builder pretty utf8 matches pretty string" {
  let node = XmlNode::element(
    "svg",
    [XmlAttr::new("xmlns", "http://www.w3.org/2000/svg")],
    [XmlNode::empty("rect", [XmlAttr::new("width", "10")])],
  )
  let pretty = xml_to_pretty_string(node, "  ")
  let utf8 = xml_to_pretty_utf8(node, "  ")
  assert_eq(@utf8.decode_lossy(utf8[:]), pretty)
}

///|
test "xml builder utf16le decodes back" {
  let node = XmlNode::element("svg", [], [
    XmlNode::element("text", [], [XmlNode::text_escaped("A中")]),
  ])
  let pretty = xml_to_pretty_string(node, "  ")
  let utf16 = xml_to_pretty_utf16le(node, "  ")
  let decoded = @utf16.decode_lossy(
    utf16[:],
    ignore_bom=true,
    endianness=@utf16.Endian::Little,
  )
  assert_eq(decoded, pretty)
}
