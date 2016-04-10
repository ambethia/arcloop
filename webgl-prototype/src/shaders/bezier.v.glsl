attribute vec4 position;
attribute vec4 fill0;
attribute vec4 fill1;
attribute float type;

uniform mat4 view;
uniform mat4 projection;

varying vec4 outerColor;
varying vec4 innerColor;
varying vec3 bezier;

void main() {
  if(        position.w == 0.0 ) {
    bezier = vec3(  1, 1, 0);
  } else if( position.w == 1.0 ) {
    bezier = vec3(0.5, 0, 0);
  } else {
    bezier = vec3(0,   0, 0);
  }
  gl_Position = projection * view * vec4(position.xyz, 1);

  if (type == 0.0) {
    outerColor = fill0 / 256.0;
    innerColor = fill1 / 256.0;
  } else if (type == 1.0) {
    outerColor = fill1 / 256.0;
    innerColor = fill0 / 256.0;
  } else {
    outerColor = fill1 / 256.0;
    innerColor = fill1 / 256.0;
  }
}
