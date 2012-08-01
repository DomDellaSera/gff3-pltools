module bio.gff3.conv.gtf;

import std.stdio;
import bio.gff3.record_range;

bool to_gtf(GenericRecordRange records, File output, long at_most = -1) {
  long counter = 0;
  bool first_attr = true;
  foreach(rec; records) {
    if (!first_attr)
      output.write(',');
    else
      first_attr = false;

    output.writeln(rec.toString(DataFormat.GTF));
    counter += 1;

    // Check if the "at_most" limit has been reached
    if (counter == at_most) {
      output.write("# ...");
      return true;
    }
  }

  return false;
}

