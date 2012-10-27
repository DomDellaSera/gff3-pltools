module bio.gff3.filtering.string_op_impl;

import bio.gff3.filtering.common, bio.gff3.filtering.node,
       bio.gff3.field_accessor, bio.gff3.record;

package:

RecordToString get_string_delegate(Node node) {
  RecordToString filter;

  final switch(node.type) {
    case NodeType.VALUE:
      filter = (record) { return node.text; };
      break;
    case NodeType.FIELD_OPERATOR:
      filter = get_field_accessor(node.parameter);
      break;
    case NodeType.ATTR_OPERATOR:
      filter = (record) {
        return (node.parameter in record.attributes) ? record.attributes[node.parameter].first : null;
      };
      break;
    case NodeType.BRACKETS:
      filter = get_string_delegate(node.children[0]);
      break;
    case NodeType.NONE:
    case NodeType.AND_OPERATOR:
    case NodeType.OR_OPERATOR:
    case NodeType.NOT_OPERATOR:
    case NodeType.CONTAINS_OPERATOR:
    case NodeType.STARTS_WITH_OPERATOR:
    case NodeType.EQUALS_OPERATOR:
    case NodeType.NOT_EQUALS_OPERATOR:
    case NodeType.GREATER_THAN_OPERATOR:
    case NodeType.LOWER_THAN_OPERATOR:
    case NodeType.GREATER_THAN_OR_EQUALS_OPERATOR:
    case NodeType.LOWER_THAN_OR_EQUALS_OPERATOR:
    case NodeType.PLUS_OPERATOR:
    case NodeType.MINUS_OPERATOR:
    case NodeType.MULTIPLICATION_OPERATOR:
    case NodeType.DIVISION_OPERATOR:
      filter = null;
      break;
  }

  return filter;
}

version(unittest) {
  import bio.gff3.attribute;
}

unittest {
  auto node = new Node(NodeType.VALUE);
  node.text = "some value";
  auto op = get_string_delegate(node);
  assert(op(new Record()) == "some value");

  node = new Node(NodeType.FIELD_OPERATOR);
  node.parameter = "feature";
  auto record = new Record();
  record.feature = "1";
  op = get_string_delegate(node);
  assert(op(record) == "1");

  node = new Node(NodeType.ATTR_OPERATOR);
  node.parameter = "ID";
  record = new Record();
  record.attributes["ID"] = AttributeValue(["1"]);
  op = get_string_delegate(node);
  assert(op(record) == "1");

  auto bracket_node = new Node(NodeType.BRACKETS);
  bracket_node.children = [node];
  bracket_node.text = "(";
  node.parent = bracket_node;
  op = get_string_delegate(bracket_node);
  assert(op(record) == "1");

  assert(get_string_delegate(new Node(NodeType.AND_OPERATOR)) is null);
}

