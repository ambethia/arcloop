#extension GL_OES_standard_derivatives : enable

precision highp float;

varying vec4 color;
varying vec3 bezier;

void main() {
  vec2 px = dFdx(bezier.st);
  vec2 py = dFdy(bezier.st);
  float fx = 2.0 * bezier.s * px.x - px.y;
  float fy = 2.0 * bezier.t * py.x - py.y;
  float sd = (pow(bezier.s, 2.0) - bezier.t) / sqrt(fx * fx + fy * fy);
  float alpha = (bezier.p == 1.0) ? 0.5 + sd : 0.5 - sd;
  gl_FragColor = vec4(color.rgb, color.a * clamp(alpha, 0.0, 1.0));
}
