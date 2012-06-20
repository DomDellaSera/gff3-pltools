module bio.gff3.filtering;

import std.algorithm, std.string, std.conv;
import bio.gff3.record;

/**
Sample usage:

set_filter(AFTER(FIELD("score",
                       EQUAL("1.0"))
set_filter(BEFORE(OR(ATTRIBUTE("ID",
                               EQUALS("hello")),
                     ATTRIBUTE("Parent",
                               EQUALS("test"))));
*/

FilterPredicate NO_FILTER;

auto FIELD(string field_name, FilterPredicate p) { return new FieldPredicate(field_name, p); }
auto ATTRIBUTE(string attribute_name, FilterPredicate p) { return new AttributePredicate(attribute_name, p); }

auto EQUALS(string value) { return new EqualsPredicate(value); }
auto STARTS_WITH(string value) { return new StartsWithPredicate(value); }
auto CONTAINS(string value) { return new ContainsPredicate(value); }

auto NOT(FilterPredicate p) { return new NotPredicate(p); }
auto AND(FilterPredicate[] predicates...) { return new AndPredicate(predicates); }
auto OR(FilterPredicate[] predicates...) { return new OrPredicate(predicates); }

class FilterPredicate {
  bool keep(string value) { return true; }
  bool keep(Record value) { return true; }
}

static this() {
  NO_FILTER = new FilterPredicate;
}

enum
   FIELD_SEQNAME = "seqname",
   FIELD_SOURCE  = "source",
   FIELD_FEATURE = "feature",
   FIELD_START   = "start",
   FIELD_END     = "end",
   FIELD_SCORE   = "score",
   FIELD_STRAND  = "strand",
   FIELD_PHASE   = "phase";

private:

class FieldPredicate : FilterPredicate {
  this(string field_name, FilterPredicate p) {
    this.p = p;
    switch(field_name) {
      case FIELD_SEQNAME:
        this.field_accessor = function string(Record r) { return r.seqname; };
        break;
      case FIELD_SOURCE:
        this.field_accessor = function string(Record r) { return r.source; };
        break;
      case FIELD_FEATURE:
        this.field_accessor = function string(Record r) { return r.feature; };
        break;
      case FIELD_START:
        this.field_accessor = function string(Record r) { return r.start; };
        break;
      case FIELD_END:
        this.field_accessor = function string(Record r) { return r.end; };
        break;
      case FIELD_SCORE:
        this.field_accessor = function string(Record r) { return r.score; };
        break;
      case FIELD_STRAND:
        this.field_accessor = function string(Record r) { return r.strand; };
        break;
      case FIELD_PHASE:
        this.field_accessor = function string(Record r) { return r.phase; };
        break;
      default:
        throw new Exception("Invalid field name: " ~ field_name);
        break;
    }
  }

  override bool keep(Record r) { return p.keep(field_accessor(r)); }

  FilterPredicate p;
  string function(Record r) field_accessor;
}

class AttributePredicate : FilterPredicate {
  this(string attribute_name, FilterPredicate p) {
    this.p = p;
    this.attribute_name = attribute_name;
  }

  override bool keep(Record r) {
    string attribute_value;
    if (attribute_name in r.attributes)
      attribute_value = r.attributes[attribute_name];
    else
      attribute_value = "";
    return p.keep(attribute_value);
  }

  FilterPredicate p;
  string attribute_name;
}

class EqualsPredicate : FilterPredicate {
  this(string value) { this.value = value; }
  override bool keep(string s) { return s == value; }

  string value;
} 

class StartsWithPredicate : FilterPredicate {
  this(string value) { this.value = value; }
  override bool keep(string s) { return s.startsWith(value); }

  string value;
}

class ContainsPredicate : FilterPredicate {
  this(string value) { this.value = value; }
  override bool keep(string s) { return std.string.indexOf(s, value) > -1; }

  string value;
}

class NotPredicate : FilterPredicate {
  this(FilterPredicate p) { this.p = p; }
  override bool keep(string s) { return !(p.keep(s)); }
  override bool keep(Record r) { return !(p.keep(r)); }

  FilterPredicate p;
}

class AndPredicate : FilterPredicate {
  this(FilterPredicate[] predicates...) {
    if (predicates.length < 2)
      throw new Exception("Invalid number of members in an AND predicate: " ~ to!string(predicates.length));
    this.predicates = new FilterPredicate[predicates.length];
    foreach(i, predicate; predicates) {
      this.predicates[i] = predicate;
    }
  }
  
  override bool keep(string s) {
    bool result = true;
    foreach(predicate; predicates) {
      result = result && predicate.keep(s);
      if (result == false)
        break;
    }
    return result;
  }

  override bool keep(Record r) {
    bool result = true;
    foreach(predicate; predicates) {
      result = result && predicate.keep(r);
      if (result == false)
        break;
    }
    return result;
  }

  FilterPredicate[] predicates;
}

class OrPredicate : FilterPredicate {
  this(FilterPredicate[] predicates...) {
    if (predicates.length < 2)
      throw new Exception("Invalid number of members in an OR predicate: " ~ to!string(predicates.length));
    this.predicates = new FilterPredicate[predicates.length];
    foreach(i, predicate; predicates) {
      this.predicates[i] = predicate;
    }
  }
  
  override bool keep(string s) {
    bool result = false;
    foreach(predicate; predicates) {
      result = result || predicate.keep(s);
      if (result == true)
        break;
    }
    return result;
  }

  override bool keep(Record r) {
    bool result = false;
    foreach(predicate; predicates) {
      result = result || predicate.keep(r);
      if (result == true)
        break;
    }
    return result;
  }

  FilterPredicate[] predicates;
}

import std.stdio;

unittest {
  writeln("Testing filtering predicates...");

  // Testing NO_FILTER
  assert(NO_FILTER.keep("") == true);
  assert(NO_FILTER.keep("test test") == true);
  assert(NO_FILTER.keep(new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1")) == true);

  // Testing FIELD
  auto test_record = new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9");
  assert(FIELD(FIELD_SEQNAME, EQUALS("1")).keep(test_record) == true);
  assert(FIELD(FIELD_SOURCE, EQUALS("2")).keep(test_record) == true);
  assert(FIELD(FIELD_FEATURE, EQUALS("3")).keep(test_record) == true);
  assert(FIELD(FIELD_START, EQUALS("4")).keep(test_record) == true);
  assert(FIELD(FIELD_END, EQUALS("5")).keep(test_record) == true);
  assert(FIELD(FIELD_SCORE, EQUALS("6")).keep(test_record) == true);
  assert(FIELD(FIELD_STRAND, EQUALS("7")).keep(test_record) == true);
  assert(FIELD(FIELD_PHASE, EQUALS("8")).keep(test_record) == true);

  assert(FIELD(FIELD_SEQNAME, EQUALS("bad value")).keep(test_record) == false);
  assert(FIELD(FIELD_SOURCE, EQUALS("bad value")).keep(test_record) == false);
  assert(FIELD(FIELD_FEATURE, EQUALS("bad value")).keep(test_record) == false);
  assert(FIELD(FIELD_START, EQUALS("bad value")).keep(test_record) == false);
  assert(FIELD(FIELD_END, EQUALS("bad value")).keep(test_record) == false);
  assert(FIELD(FIELD_SCORE, EQUALS("bad value")).keep(test_record) == false);
  assert(FIELD(FIELD_STRAND, EQUALS("bad value")).keep(test_record) == false);
  assert(FIELD(FIELD_PHASE, EQUALS("bad value")).keep(test_record) == false);

  test_record = new Record(" \t.\ta\t123\t456\t1.0\t+\t2\tID=9");
  assert(FIELD(FIELD_SEQNAME, EQUALS(" ")).keep(test_record) == true);
  assert(FIELD(FIELD_SOURCE, EQUALS(".")).keep(test_record) == true);
  assert(FIELD(FIELD_FEATURE, EQUALS("a")).keep(test_record) == true);
  assert(FIELD(FIELD_START, EQUALS("123")).keep(test_record) == true);
  assert(FIELD(FIELD_END, EQUALS("456")).keep(test_record) == true);
  assert(FIELD(FIELD_SCORE, EQUALS("1.0")).keep(test_record) == true);
  assert(FIELD(FIELD_STRAND, EQUALS("+")).keep(test_record) == true);
  assert(FIELD(FIELD_PHASE, EQUALS("2")).keep(test_record) == true);

  // Testing ATTRIBUTE
  test_record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=1;test=value");
  assert(ATTRIBUTE("ID", EQUALS("1")).keep(test_record) == true);
  assert(ATTRIBUTE("Parent", EQUALS("")).keep(test_record) == true);
  assert(ATTRIBUTE("Parent", EQUALS("123")).keep(test_record) == false);
  assert(ATTRIBUTE("test", EQUALS("value")).keep(test_record) == true);

  test_record = new Record(".\t.\t.\t.\t.\t.\t.\t.\t.");
  assert(ATTRIBUTE("Parent", EQUALS("123")).keep(test_record) == false);
  assert(ATTRIBUTE("ID", EQUALS("123")).keep(test_record) == false);
  assert(ATTRIBUTE("ID", EQUALS("")).keep(test_record) == true);

  test_record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=");
  assert(ATTRIBUTE("ID", EQUALS("")).keep(test_record) == true);

  // Testing EQUALS
  assert(EQUALS("abc").keep("abc") == true);
  assert(EQUALS("123").keep("123") == true);
  assert(EQUALS("abc").keep("def") == false);
  assert(EQUALS("abc").keep("a") == false);
  assert(EQUALS("abc").keep("") == false);
  assert(EQUALS("").keep("abc") == false);
  assert(EQUALS("").keep("") == true);

  // Testing STARTS_WITH
  assert(STARTS_WITH("abc").keep("abc") == true);
  assert(STARTS_WITH("abc").keep("abcdef") == true);
  assert(STARTS_WITH("abc").keep("ab") == false);
  assert(STARTS_WITH("abc").keep("a") == false);
  assert(STARTS_WITH("abc").keep("") == false);
  assert(STARTS_WITH("").keep("") == true);
  assert(STARTS_WITH("").keep("abc") == true);
  assert(STARTS_WITH("a").keep("abc") == true);
  assert(STARTS_WITH("a").keep("") == false);
  assert(STARTS_WITH("123").keep("1234") == true);

  // Testing CONTAINS
  assert(CONTAINS("abc").keep("abc") == true);
  assert(CONTAINS("abc").keep("0abcdef") == true);
  assert(CONTAINS("a").keep("0abcdef") == true);
  assert(CONTAINS("").keep("0abcdef") == true);
  assert(CONTAINS("abc").keep("") == false);
  assert(CONTAINS("abc").keep("a") == false);
  assert(CONTAINS("abc").keep("b") == false);
  assert(CONTAINS("abc").keep("c") == false);

  // Testing NOT
  assert(NOT(EQUALS("abc")).keep("abc") == false);
  assert(NOT(EQUALS("abc")).keep("a") == true);
  assert(NOT(CONTAINS("abc")).keep("c") == true);
  assert(NOT(STARTS_WITH("123")).keep("1234") == false);
  test_record = new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9");
  assert(NOT(FIELD(FIELD_SEQNAME, EQUALS("1"))).keep(test_record) == false);
  assert(NOT(ATTRIBUTE("ID", EQUALS("1"))).keep(test_record) == true);

  // Testing AND
  test_record = new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9");
  assert(AND(FIELD(FIELD_SEQNAME, EQUALS("1")), FIELD(FIELD_SOURCE, EQUALS("2"))).keep(test_record) == true);
  assert(AND(FIELD(FIELD_SEQNAME, EQUALS("1")), FIELD(FIELD_SOURCE, EQUALS("3"))).keep(test_record) == false);
  assert(AND(FIELD(FIELD_SEQNAME, EQUALS("3")), FIELD(FIELD_SOURCE, EQUALS("2"))).keep(test_record) == false);
  assert(AND(FIELD(FIELD_SEQNAME, EQUALS("3")), FIELD(FIELD_SOURCE, EQUALS("3"))).keep(test_record) == false);
  assert(AND(NOT(FIELD(FIELD_SEQNAME, EQUALS("1"))), FIELD(FIELD_SOURCE, EQUALS("2"))).keep(test_record) == false);
  assert(AND(NOT(FIELD(FIELD_SEQNAME, EQUALS("3"))), FIELD(FIELD_SOURCE, EQUALS("2"))).keep(test_record) == true);
  assert(AND(NOT(FIELD(FIELD_SEQNAME, EQUALS("3"))),
             FIELD(FIELD_SOURCE, EQUALS("2")),
             FIELD(FIELD_SEQNAME, EQUALS("1"))).keep(test_record) == true);

  // Testing OR
  test_record = new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=9");
  assert(OR(FIELD(FIELD_SEQNAME, EQUALS("1")), FIELD(FIELD_SOURCE, EQUALS("2"))).keep(test_record) == true);
  assert(OR(FIELD(FIELD_SEQNAME, EQUALS("1")), FIELD(FIELD_SOURCE, EQUALS("3"))).keep(test_record) == true);
  assert(OR(FIELD(FIELD_SEQNAME, EQUALS("3")), FIELD(FIELD_SOURCE, EQUALS("2"))).keep(test_record) == true);
  assert(OR(FIELD(FIELD_SEQNAME, EQUALS("3")), FIELD(FIELD_SOURCE, EQUALS("3"))).keep(test_record) == false);
  assert(OR(NOT(FIELD(FIELD_SEQNAME, EQUALS("1"))), FIELD(FIELD_SOURCE, EQUALS("2"))).keep(test_record) == true);
  assert(OR(NOT(FIELD(FIELD_SEQNAME, EQUALS("3"))), FIELD(FIELD_SOURCE, EQUALS("2"))).keep(test_record) == true);
  assert(OR(NOT(FIELD(FIELD_SEQNAME, EQUALS("1"))),
            FIELD(FIELD_SOURCE, EQUALS("2")),
            FIELD(FIELD_SEQNAME, EQUALS("3"))).keep(test_record) == true);
}