package;

import format.swf.Data;
using Lambda;

class Main {

  var shapes : Map<Int, Shape>;
  var clips : Map<Int, Clip>;

  static function main() {
    var parser = new Main();

    var animations = new Map<String, Dynamic>();
    var shapes = new Array<Dynamic>();

    for( clip in parser.clips ) {
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

    for( key in parser.shapes.keys() ) {
      var shape = parser.shapes[key].parts.map(function(part) {
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

    var json : String = haxe.Json.stringify({
      animations : animations,
      shapes : shapes
    });

    Sys.println(json);
  }

  public static function colorToInt(color:Color) : UInt {
    return color.r << 24 | color.g << 16 | color.b << 8 | color.a;
  }

  public static function isLeft(a : Point, b : Point, c : Point) : Bool {
    return ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) > 0;
  }

  public function new() {
    var path = Sys.args()[0];
    var bytes = sys.io.File.getBytes(path);
    this.shapes = new Map<Int, Shape>();
    this.clips = new Map<Int, Clip>();
    parse(bytes);
  }

  function parse(bytes : haxe.io.Bytes) : Void {
    var io = new haxe.io.BytesInput(bytes);
    var data = new format.swf.Reader(io).read();
    io.close();
    handleTags(data.tags);
  }

  function handleTags(tags : Array<format.swf.SWFTag>) : Void {
    for( tag in tags ) {
      parseTag(tag);
    }
  }

  function parseTag(tag : format.swf.SWFTag) : Void {
    switch(tag) {
      case TShape(id, data):
        this.shapes[id] = handleShape(data);
      case TClip(id, frames, data):
        this.clips[id] = handleClip(data);
      case TSymbolClass(symbols):
        for(symbol in  symbols) {
          var clip = this.clips[symbol.cid];
          if( clip != null ) {
            clip.name = symbol.className;
          }
        }
      case TSandBox(_), TBackgroundColor(_), TUnknown(_), TActionScript3(_), TShowFrame:
      default:
        trace('Unhandled Tag', format.swf.Tools.dumpTag(tag));
    }
  }

  function handleClip(tags : Array<format.swf.SWFTag>) : Clip {
    var clip : Clip = { frames: [] };
    var actors = new Map<Int, Actor>();
    for( tag in tags ) {
      switch tag {
        case TPlaceObject2(object):
          // TODO Transforms
          if( object.cid != null ) {
            actors[object.depth] = { shape: object.cid };
          } else {
            trace('Unhandled Missing CID', object);
          }
        case TShowFrame:
          var inFrame = new Map<Int, Actor>();
          for (depth in actors.keys()) {
            inFrame[depth] = {
              shape : actors[depth].shape
              // TODO COPY TRANSFORM
            };
          }
          clip.frames.push({ actors: inFrame });
        default:
          trace('Unhandled Clip Tag', tag);
      }
    }
    return clip;
  };

  function handleShape(data : format.swf.ShapeData) : Shape {
    var currentPoint = new Point();
    var currentPoly = { points : new Array<Point>() };
    var shape = { parts: [] };
    var fills = new Array<format.swf.FillStyle>();
    switch data {
      case SHDShape1(bounds, shapes) |
           SHDShape2(bounds, shapes) |
           SHDShape3(bounds, shapes):
        var part : Part = new Part([{ r : 0, g : 0, b : 0, a: 0 }, { r : 0, g : 0, b : 0, a: 0 }]);
        fills = shapes.fillStyles;
        for( record in shapes.shapeRecords ) {
          var currentPartFills = part.fills.copy();
          switch record {
            case SHRChange(change):
              if ( part.curves.length != 0 ) {
                shape.parts.push(part);
                part = new Part(part.fills.copy());
              }
              if( change.newStyles != null && change.newStyles.fillStyles != null ) {
                fills = change.newStyles.fillStyles;
              }
              if( change.fillStyle0 != null ) {
                if( change.fillStyle0.idx > 0 ) {
                  var fill = fills[change.fillStyle0.idx - 1];
                  switch fill {
                    case FSSolid(c):
                      part.fills[0] = { r : c.r, g : c.g, b : c.b, a: 255 }
                    default:
                      trace('Unsupported Fill Style', fill);
                  }
                } else {
                  part.fills[0] = { r : 0, g : 0, b : 0, a: 0 };
                }
              }
              if( change.fillStyle1 != null ) {
                if( change.fillStyle1.idx > 0 ) {
                  var fill = fills[change.fillStyle1.idx - 1];
                  switch fill {
                    case FSSolid(c):
                      part.fills[1] = { r : c.r, g : c.g, b : c.b, a: 255 }
                    default:
                      trace('Unsupported Fill Style', fill);
                  }
                } else {
                  part.fills[1] = { r : 0, g : 0, b : 0, a: 0 };
                }
              }
              if (change.moveTo != null) {
                currentPoint = new Point(change.moveTo.dx, change.moveTo.dy);
                if( currentPoly.points.length > 0 ) {
                  part.polys.push(currentPoly);
                  currentPoly = { points : new Array<Point>() }
                }
              }
              // If the fills have changed, create a new part
              // (colorToInt(currentPartFills[0]) != colorToInt(part.fills[0]) ||
              //     colorToInt(currentPartFills[1]) != colorToInt(part.fix`lls[1])) &&

            case SHRCurvedEdge(cdx, cdy, adx, ady):
              var controlPoint = currentPoint.add(cdx, cdy);
              var anchorPoint = controlPoint.add(adx, ady);
              var type = isLeft(currentPoint, controlPoint, anchorPoint) ? ConvexCurve : ConcaveCurve;
              part.curves.push({ a : currentPoint, b : controlPoint, c : anchorPoint,  type: type });
              currentPoint = anchorPoint;
              currentPoly.points.push(currentPoint.copy());
            case SHREdge(dx, dy):
              currentPoint = currentPoint.add(dx, dy);
              currentPoly.points.push(currentPoint.copy());
            case SHREnd:
              part.polys.push(currentPoly);
              shape.parts.push(part);
          }
        }
      case SHDShape4(shapes):
        trace('Unhandled Shape', shapes);
    };
    return shape;
  }
}

class Point {
  public var x : Int;
  public var y : Int;

  public function new(x : Int = 0, y : Int = 0) {
    this.x = x;
    this.y = y;
  }

  public function add(x : Int = 0, y : Int = 0) : Point {
    return new Point(this.x + x, this.y + y);
  }

  public function toA() : Array<Int> {
    return [this.x, this.y];
  }

  public function p2t() : org.poly2tri.Point {
    return new org.poly2tri.Point(this.x, this.y);
  }

  public function copy() : Point {
    return new Point(this.x, this.y);
  }
}

enum TriangleType {
  ConvexCurve;
  ConcaveCurve;
  SolidTriangle;
}

typedef Triangle = {
  var a : Point;
  var b : Point;
  var c : Point;
  var type: TriangleType;
};

typedef Color = {
  var r : Int;
  var g : Int;
  var b : Int;
  var a : Int;
};

typedef Transform = {
}

typedef Actor = {
  var shape : Int;
  @:optional var transform : Transform;
}

typedef Frame = {
  var actors : Map<Int, Actor>;
}

typedef Clip = {
  @:optional var name : String;
  var frames : Array<Frame>;
}

typedef Shape = {
  var parts : Array<Part>;
}

typedef Poly = {
  var points : Array<Point>;
}

class Part {
  public var fills : Array<Color>;
  public var curves : Array<Triangle>;
  public var polys : Array<Poly>;

  public function new(fills : Array<Color>) {
    this.fills = fills;
    this.curves = new Array<Triangle>();
    this.polys = new Array<Poly>();
  }
}
