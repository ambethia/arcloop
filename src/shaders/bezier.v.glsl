attribute vec4 position;
attribute vec4 fill;

uniform mat4 view;
uniform mat4 projection;

varying vec4 color;
varying vec3 bezier;

void main() {
  if(position.w == 0.0) {
    bezier = vec3(1, 1, 0);
  } else if(position.w == 1.0) {
    bezier = vec3(0.5, 0, 0);
  } else {
    bezier = vec3(0, 0, 0);
  }
  gl_Position = projection * view * vec4(position.xyz, 1);
  color = vec4(fill.rgb / 256.0, fill.a);
}
