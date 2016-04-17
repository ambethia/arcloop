package xyz.arcloop.swflux;

interface Edge {
  var points : Array<Point>;
  public function connectsTo(edge : Edge) : Bool;
}

class StraightEdge implements Edge {
  public var points : Array<Point>;

  public function new(a : Point, b : Point) {
    this.points = [a, b];
  }

  public function connectsTo(edge : Edge) : Bool {
    return this.points[1] == edge.points[0];
  }
}

class CurvedEdge implements Edge {
  public var points : Array<Point>;

  public function new(a : Point, b : Point, c : Point) {
    this.points = [a, b, c];
  }

  public function connectsTo(edge : Edge) : Bool {
    return this.points[2] == edge.points[0];
  }

  public function toTri() : Triangle {
    var type = isConvex() ? ConvexCurve : ConcaveCurve;
    return new Triangle(this.points[0], this.points[1], this.points[2], type);
  }

  function isConvex() : Bool {
    var a = this.points[0];
    var b = this.points[1];
    var c = this.points[2];
    return ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) > 0;
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

typedef Part = {
  var fill : Color;
  var edges : Array<Edge>;
};

enum TriangleType {
  ConvexCurve;
  ConcaveCurve;
  SolidTriangle;
}

class Triangle {
  public var a : Point;
  public var b : Point;
  public var c : Point;
  public var type : TriangleType;

  public function new(a : Point, b : Point, c : Point, type : TriangleType) {
    this.a = a;
    this.b = b;
    this.c = c;
    this.type = type;
  }

  public function serialize() : Array<Dynamic> {
    return [[a.x, a.y], [b.x, b.y], [c.x, c.y], type];
  }
}

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
