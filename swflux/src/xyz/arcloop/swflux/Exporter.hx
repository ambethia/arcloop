package xyz.arcloop.swflux;

import xyz.arcloop.swflux.Importer;
import xyz.arcloop.swflux.Util;

class Exporter {
  var animations : Map<String, Dynamic>;
  var shapes : Array<Dynamic>;

  public function new(importer : Importer) {
    this.animations = new Map<String, Dynamic>();
    this.shapes = new Array<Dynamic>();

    for( clip in importer.clips ) {
      if( clip.name != null ) {
        var frames = new Array<Array<Int>>();
        for( frame in clip.frames ) {
          var actors = new Array<Int>();
          var currentDepth = 0;
          for(depth in frame.actors.keys()) {
            var actor = frame.actors[depth].shape - 1;
            depth < currentDepth ? actors.unshift(actor) : actors.push(actor);
          }
          frames.push(actors);
        }
        animations[clip.name] = { frames : frames };
      }
    }

    for( key in importer.shapes.keys() ) {
      var shape = importer.shapes[key].parts.map(function(part) {
        var triangles = new Array<Dynamic>();

        for (tri in part.curves) {
          var tri : Array<Dynamic> = [tri.a.toA(), tri.b.toA(), tri.c.toA(), tri.type];
          triangles.push(tri);
        };

        if( part.polys.length > 0 ) {
          var vp = new org.poly2tri.VisiblePolygon();
          for( poly in part.polys ) {
            vp.addPolyline(poly.points.map(function(point) { return point.p2t(); }));
          }
          vp.performTriangulationOnce();
          var verts = vp.getVerticesAndTriangles().vertices;
          var tris = vp.getVerticesAndTriangles().triangles;
          for(i in 0...vp.getNumTriangles() ) {
            var a : Array<Dynamic> = [
              [
                verts[tris[i]*3],
                verts[tris[i]*3+1]
              ],
              [
                verts[tris[i+1]*3],
                verts[tris[i+1]*3+1]
              ],
              [
                verts[tris[i+2]*3],
                verts[tris[i+2]*3+1]
              ],
              SolidTriangle
            ];
            triangles.push(a);
          }
        }

        return {
          fills : [
            colorToInt(part.fills[0]),
            colorToInt(part.fills[1])
          ],
          tris : triangles
        }
      });
      shapes[key-1] = shape;
    }
  }

  public function print() {    
    var json : String = haxe.Json.stringify({
      animations : animations,
      shapes : shapes
    });

    Sys.println(json);
  }

  public static function colorToInt(color:Color) : UInt {
    return color.r << 24 | color.g << 16 | color.b << 8 | color.a;
  }
}
