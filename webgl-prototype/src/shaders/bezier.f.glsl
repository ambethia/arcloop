precision mediump float;

varying vec4 color;
varying vec3 bezier;

void main() {
  float d = bezier.s * bezier.s - bezier.t;
  if (bezier.p == 0.0) {
    if (d < 0.0) {
      discard;
    } else {
      gl_FragColor = color;
    };
  } else {
    if (d > 0.0) {
      discard;
    } else {
      gl_FragColor = color;
    };
  }
}
