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
        switch data {
          case SHDShape1(bounds, shape) |
               SHDShape2(bounds, shape) |
               SHDShape3(bounds, shape):
                this.shapes[id] = handleShape(bounds, shape);
          case SHDShape4(shape):
            trace('Unhandled Shape', shape);
        }
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

  function handleShape(bounds : format.swf.Rect, shapeData : format.swf.ShapeWithStyleData) : Shape {
    var fillStyle0 : format.swf.FillStyle = null;
    var fillStyle1 : format.swf.FillStyle = null;
    var currentFills = shapeData.fillStyles;
    var currentPoint = new Point();
    var fillEdges = new Map<format.swf.FillStyle, Array<Edge>>();
    var fillList = new Array<format.swf.FillStyle>();
    for( record in shapeData.shapeRecords ) {
      switch record {
        case SHRChange(data):
          if( data.moveTo != null )
            currentPoint = new Point(data.moveTo.dx, data.moveTo.dy);
          if( data.newStyles != null && data.newStyles.fillStyles != null )
            currentFills = data.newStyles.fillStyles;
          if( data.fillStyle0 != null )
            fillStyle0 = data.fillStyle0.idx > 0 ? currentFills[data.fillStyle0.idx - 1] : null;
          if( data.fillStyle1 != null )
            fillStyle0 = data.fillStyle1.idx > 0 ? currentFills[data.fillStyle1.idx - 1] : null;
        case SHREdge(dx, dy):
          var anchorPoint = currentPoint.add(dx, dy);
          if( fillStyle0 != null ) {
            if( fillEdges[fillStyle0] == null ) {
              fillEdges[fillStyle0] = new Array<Edge>();
              fillList.push(fillStyle0);
            }
            fillEdges[fillStyle0].push(new StraightEdge(anchorPoint, currentPoint));
            currentPoint = anchorPoint;
          }
          if( fillStyle1 != null ) {
            if( fillEdges[fillStyle1] == null ) {
              fillEdges[fillStyle1] = new Array<Edge>();
              fillList.push(fillStyle1);
            }
            fillEdges[fillStyle1].push(new StraightEdge(currentPoint, anchorPoint));
          }
        case SHRCurvedEdge(cdx, cdy, adx, ady):
          var controlPoint = currentPoint.add(cdx, cdy);
          var anchorPoint = controlPoint.add(adx, ady);
          if( fillStyle0 != null ) {
            if( fillEdges[fillStyle0] == null ) {
              fillEdges[fillStyle0] = new Array<Edge>();
              fillList.push(fillStyle0);
            }
            fillEdges[fillStyle0].push(new CurvedEdge(anchorPoint, controlPoint, currentPoint));
          }
          if( fillStyle1 != null ) {
            if( fillEdges[fillStyle1] == null ) {
              fillEdges[fillStyle1] = new Array<Edge>();
              fillList.push(fillStyle1);
            }
            fillEdges[fillStyle1].push(new CurvedEdge(currentPoint, controlPoint, anchorPoint));
          }
          currentPoint = anchorPoint;
        case SHREnd:
          // ?
      }
    }

    var shape = { parts: [] };

    for( fill in fillList ) {
      var path = new Array<Edge>();
      var remaining = fillEdges[fill];
      var current = remaining[0];
      while( !remaining.empty() ) {
        path.push(current);
        remaining.remove(current);
        if( !remaining.empty() ) {
          var connectingEdges = remaining.filter(function(edge : Edge) : Bool {
            return current.connectsTo(edge);
          });
          if( !connectingEdges.empty() ) {
            current = remaining[remaining.indexOf(connectingEdges[0])];
          } else {
            current = remaining[0];
          }
        }
      }

      shape.parts.push({
        fill: fillToColor(fill),
        edges: path
      });
    }
    return shape;
  }

  // function handleShape(data : format.swf.ShapeData) : Shape {
  //   var currentPoint = new Point();
  //   var currentPoly = { points : new Array<Point>() };
  //   var shape = { parts: [] };
  //   var fills = new Array<format.swf.FillStyle>();
  //   switch data {
  //     case SHDShape1(bounds, shapes) |
  //          SHDShape2(bounds, shapes) |
  //          SHDShape3(bounds, shapes):
  //       var part : Part = new Part([{ r : 0, g : 0, b : 0, a: 0 }, { r : 0, g : 0, b : 0, a: 0 }]);
  //       fills = shapes.fillStyles;
  //       for( record in shapes.shapeRecords ) {
  //         var currentPartFills = part.fills.copy();
  //         switch record {
  //           case SHRChange(change):
  //             if ( part.curves.length != 0 ) {
  //               shape.parts.push(part);
  //               part = new Part(part.fills.copy());
  //             }
  //             if( change.newStyles != null && change.newStyles.fillStyles != null ) {
  //               fills = change.newStyles.fillStyles;
  //             }
  //             if( change.fillStyle0 != null ) {
  //               if( change.fillStyle0.idx > 0 ) {
  //                 var fill = fills[change.fillStyle0.idx - 1];
  //                 switch fill {
  //                   case FSSolid(c):
  //                     part.fills[0] = { r : c.r, g : c.g, b : c.b, a: 255 }
  //                   default:
  //                     trace('Unsupported Fill Style', fill);
  //                 }
  //               } else {
  //                 part.fills[0] = { r : 0, g : 0, b : 0, a: 0 };
  //               }
  //             }
  //             if( change.fillStyle1 != null ) {
  //               if( change.fillStyle1.idx > 0 ) {
  //                 var fill = fills[change.fillStyle1.idx - 1];
  //                 switch fill {
  //                   case FSSolid(c):
  //                     part.fills[1] = { r : c.r, g : c.g, b : c.b, a: 255 }
  //                   default:
  //                     trace('Unsupported Fill Style', fill);
  //                 }
  //               } else {
  //                 part.fills[1] = { r : 0, g : 0, b : 0, a: 0 };
  //               }
  //             }
  //             if (change.moveTo != null) {
  //               currentPoint = new Point(change.moveTo.dx, change.moveTo.dy);
  //               if( currentPoly.points.length > 0 ) {
  //                 part.polys.push(currentPoly);
  //                 currentPoly = { points : new Array<Point>() }
  //               }
  //             }
  //             // If the fills have changed, create a new part
  //             // (colorToInt(currentPartFills[0]) != colorToInt(part.fills[0]) ||
  //             //     colorToInt(currentPartFills[1]) != colorToInt(part.fix`lls[1])) &&
  //
  //           case SHRCurvedEdge(cdx, cdy, adx, ady):
  //             var controlPoint = currentPoint.add(cdx, cdy);
  //             var anchorPoint = controlPoint.add(adx, ady);
  //             var type = isLeft(currentPoint, controlPoint, anchorPoint) ? ConvexCurve : ConcaveCurve;
  //             part.curves.push({ a : currentPoint, b : controlPoint, c : anchorPoint,  type: type });
  //             currentPoint = anchorPoint;
  //             currentPoly.points.push(currentPoint.copy());
  //           case SHREdge(dx, dy):
  //             currentPoint = currentPoint.add(dx, dy);
  //             currentPoly.points.push(currentPoint.copy());
  //           case SHREnd:
  //             part.polys.push(currentPoly);
  //             shape.parts.push(part);
  //         }
  //       }
  //     case SHDShape4(shapes):
  //       trace('Unhandled Shape', shapes);
  //   };
  //   return shape;
  // }

  public static function fillToColor(fill : format.swf.FillStyle) : Color {
    switch fill {
      case FSSolid(c):
        return { r : c.r, g : c.g, b : c.b, a: 255 }
      default:
        trace('Unsupported Fill Style', fill);
        return { r : 0, g : 0, b : 0, a: 255 };
    }
  }
}
