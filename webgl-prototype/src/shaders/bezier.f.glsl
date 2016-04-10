precision mediump float;

varying vec4 outerColor;
varying vec4 innerColor;
varying vec3 bezier;

void main() {
  float d = bezier.s * bezier.s - bezier.t;
  if (bezier.p == 0.0) {
    if (d < 0.0) {
      gl_FragColor = innerColor;
    } else {
      gl_FragColor = outerColor;
    };
  } else {
    if (d > 0.0) {
      gl_FragColor = innerColor;
    } else {
      gl_FragColor = outerColor;
    };
  }
}
