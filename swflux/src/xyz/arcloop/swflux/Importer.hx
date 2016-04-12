package xyz.arcloop.swflux;

import xyz.arcloop.swflux.Util;

import format.swf.Data;
using Lambda;

class Importer {

  public var shapes : Map<Int, Shape>;
  public var clips : Map<Int, Clip>;

  public function new(bytes : haxe.io.Bytes) {
    this.shapes = new Map<Int, Shape>();
    this.clips = new Map<Int, Clip>();

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

  public static function isLeft(a : Point, b : Point, c : Point) : Bool {
    return ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) > 0;
  }
}
