module util.split_into_lines;

import std.string, std.stdio, std.conv;

/**
 * A string splitter, which defers parsing until front is called.
 * The constructor takes a string, detects what the line terminator
 * is and then when front is called, the next line in the string is
 * detected and retrieved. Also, there is no copying involved, only
 * slicing.
 */
class SplitIntoLines {
  this(string data) {
    this.data = data;
    this.newline = detect_newline_delim(data);
  }

  /**
   * Returns the next line in range.
   */
  string front() {
    if (cache is null)
      cache = next_line();
    return cache;
  }

  /**
   * Pops the next line of the range.
   */
  void popFront() {
    if (cache is null)
      next_line();
    cache = next_line();
  }

  /**
   * Return true if no more lines left in the range.
   */
  bool empty() {
    if (cache is null)
      return (cache = next_line()) is null;
    else
      return false;
  }
  
  private {
    string cache;
    string newline;
    string data;

    string next_line() {
      string line = string.init;
      if (!(data is null)) {
        auto nl_index = indexOf(data, newline);
        if (nl_index == -1) {
          // last line
          line = data;
          data = null;
        } else {
          line = data[0..nl_index];
          data = data[(nl_index+newline.length)..$];
        }
      }
      return line;
    }
  }
}

/**
 * Detects the character or a character sequence which is used in the string
 * for line termination.
 */
string detect_newline_delim(string data) {
  // TODO: Implement a better line termination detection strategy
  //
  // FIXME: We can assume newlines are platform specific. D has a way of handling these. 
  //        Any digressions are resposibility of the user, not this library.
  return "\n";
}

unittest {
  writeln("Testing SplitIntoLines...");
  auto lines = new SplitIntoLines("Test\n1\n2\n3");
  assert(lines.empty == false);
  assert(lines.front == "Test"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == "1"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == "2"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == "3"); lines.popFront();
  assert(lines.empty == true);
  
  // Test for correct behavior when newline at the end of the file
  lines = new SplitIntoLines("Test newline at the end\n");
  assert(lines.empty == false);
  assert(lines.front == "Test newline at the end"); lines.popFront();
  assert(lines.empty == false);
  assert(lines.front == ""); lines.popFront();
  assert(lines.empty == true);

  // Test if it's working with foreach
  lines = new SplitIntoLines("1\n2\n3\n4");
  int i = 1;
  foreach(value; lines) {
    assert(value == to!string(i));
    i++;
  }
}

