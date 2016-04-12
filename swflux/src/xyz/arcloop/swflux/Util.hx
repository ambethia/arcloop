package xyz.arcloop.swflux;

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
