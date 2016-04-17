attribute vec4 position;
attribute vec4 fill;
attribute float type;

uniform mat4 view;
uniform mat4 projection;

varying vec4 color;
varying vec3 bezier;

void main() {
  if(        position.w == 0.0 ) {
    bezier = vec3(  1, 1, type);
  } else if( position.w == 1.0 ) {
    bezier = vec3(0.5, 0, type);
  } else {
    bezier = vec3(0,   0, type);
  }
  gl_Position = projection * view * vec4(position.xyz, 1);
  color = fill / 256.0;
}
