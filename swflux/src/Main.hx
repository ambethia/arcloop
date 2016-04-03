package;

import format.swf.Data;
using Lambda;

class Main {

  var shapes : Map<Int, Array<Shape>>;
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
      var shape = parser.shapes[key].map(function(part) {
        return {
          fill : [part.fill.r, part.fill.g, part.fill.b, part.fill.a],
          curves : part.curves.map(function(tri) {
            return [tri.a.toA(), tri.b.toA(), tri.c.toA()];
          })
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

  public function new() {
    var path = Sys.args()[0];
    var bytes = sys.io.File.getBytes(path);
    this.shapes = new Map<Int, Array<Shape>>();
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
        trace('unhanded', format.swf.Tools.dumpTag(tag));
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
            trace('Unhandled missing CID', object);
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

  function handleShape(data : format.swf.ShapeData) : Array<Shape> {
    var currentPoint = new Point();
    var parts = new Array<Shape>();
    var fills = new Array<format.swf.FillStyle>();
    switch data {
      case SHDShape1(bounds, shapes) |
           SHDShape2(bounds, shapes) |
           SHDShape3(bounds, shapes):
        var part : Shape = new Shape();
        for( record in shapes.shapeRecords ) {
          fills = shapes.fillStyles;
          switch record {
            case SHRChange(data):
              if( data.newStyles != null && data.newStyles.fillStyles != null ) {
                fills = data.newStyles.fillStyles;
              }
              if( data.fillStyle1 != null ) {
                if( data.fillStyle1.idx > 0 ) {
                  var fill = fills[data.fillStyle1.idx - 1];
                  switch fill {
                    case FSSolid(rgb):
                      part.fill = { r : rgb.r, g : rgb.g, b : rgb.b, a: 1 }
                    default:
                      trace('Unhandled Fill', fill);
                  }
                } else {
                  trace('Unhandled empty fill');
                }
              }
              if (data.moveTo != null) {
                currentPoint = new Point(data.moveTo.dx, data.moveTo.dy);
              }
            case SHRCurvedEdge(cdx, cdy, adx, ady):
              var controlPoint = currentPoint.add(cdx, cdy);
              var anchorPoint = controlPoint.add(adx, ady);
              part.curves.push({ a : currentPoint, b : controlPoint, c : anchorPoint });
              currentPoint = anchorPoint;
            case SHREdge(dx, dy):
              currentPoint = currentPoint.add(dx, dy);
            case SHREnd:
              parts.push(part);
          }
        }
      case SHDShape4(shapes):
        trace('Unhandled Shape', shapes);
    };
    return parts;
  }
}

class Point {
  var x : Int;
  var y : Int;

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
}

typedef Triangle = {
  var a : Point;
  var b : Point;
  var c : Point;
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

class Shape {
  public var fill : Color;
  public var curves : Array<Triangle>;

  public function new() {
    this.fill = { r : 1, g : 1, b : 1, a : 1 };
    this.curves = new Array<Triangle>();
  }
}
