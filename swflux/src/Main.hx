package;

import xyz.arcloop.swflux.Importer;
import xyz.arcloop.swflux.Exporter;
import xyz.arcloop.swflux.Util;

class Main {

  static function main() {
    var path = Sys.args()[0];
    var bytes = sys.io.File.getBytes(path);
    var importer = new Importer(bytes);
    var exporter = new Exporter(importer);

    exporter.print();
  }
}
