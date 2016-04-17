import './main.css';
import vertexShader from './shaders/bezier.v.glsl';
import fragmentShader from './shaders/bezier.f.glsl';
import aaFragmentShader from './shaders/bezier-aa.f.glsl';
import createProgram from './shaders/createProgram';

// import animData from '../test/simple.json';
// import animData from '../test/blob.json';
import animData from '../test/layers.json';

import { mat4 } from 'gl-matrix';

function resizeCanvas() {
  let width  = canvas.clientWidth;
  let height = canvas.clientHeight;
  if (canvas.width  != width ||
      canvas.height != height) {
    canvas.width  = width;
    canvas.height = height;
    gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
    mat4.lookAt(viewMatrix, [0,0,1], [0,0,0], [0,1,0]);
    mat4.ortho(projectionMatrix, -width*2, width*2, height*2, -height*2, 0, 200);
  }
}

const ANIMATION_TIMING = 30;
const VEC_ATTR_LENGTH = 9;
const canvas = document.createElement('canvas');
const gl = canvas.getContext('webgl');
window.gl = gl;
const aaEnabled = false; //gl.getExtension('OES_standard_derivatives') != -1;
// gl.enable(gl.DEPTH_TEST);
gl.enable(gl.BLEND);
gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
const shaderProgram = createProgram(gl, vertexShader, aaEnabled ? aaFragmentShader : fragmentShader);
const positionLocation = gl.getAttribLocation(shaderProgram, 'position');
const typeLocation = gl.getAttribLocation(shaderProgram, 'type');
const fillLocation = gl.getAttribLocation(shaderProgram, 'fill');
const buffer = gl.createBuffer();
const viewMatrix = mat4.create();
const projectionMatrix = mat4.create();
const viewLocation = gl.getUniformLocation(shaderProgram, 'view');
const projectionLocation = gl.getUniformLocation(shaderProgram, 'projection');

let frameDelta = 0;
let globalFrame = 0;
let data = [];

function update() {
  let anim = animData.animations['hole'];
  let i = globalFrame % anim.frames.length;
  let f = anim.frames[i];
  data = animData.shapes[f].reduce((shapes, shape, d) => {
    let fill = extractRGBA(shape.fill);
    return shapes.concat(shape.tris.reduce((tris, tri) => {
      return tris.concat([
        tri[0][0], tri[0][1], -d, 0, tri[3], ...fill,
        tri[1][0], tri[1][1], -d, 1, tri[3], ...fill,
        tri[2][0], tri[2][1], -d, 2, tri[3], ...fill,
      ]);
    }, []));
  }, []);
  globalFrame++;
}

function extractRGBA(n) {
  return [
    n >> 24 & 255,
    n >> 16 & 255,
    n >>  8 & 255,
    n       & 255
  ]
}

function render() {
  resizeCanvas();

  gl.clearColor(1, 1, 1, 1);
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

  if (data.length > 0) {
    gl.uniformMatrix4fv(viewLocation, false, viewMatrix);
    gl.uniformMatrix4fv(projectionLocation, false, projectionMatrix);
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Int16Array(data), gl.STATIC_DRAW);
    gl.enableVertexAttribArray(positionLocation);
    gl.enableVertexAttribArray(typeLocation);
    gl.enableVertexAttribArray(fillLocation);
    gl.vertexAttribPointer(positionLocation, 4, gl.SHORT, false, VEC_ATTR_LENGTH * Int16Array.BYTES_PER_ELEMENT, 0);
    gl.vertexAttribPointer(typeLocation, 1, gl.SHORT, false, VEC_ATTR_LENGTH * Int16Array.BYTES_PER_ELEMENT, 4 * Int16Array.BYTES_PER_ELEMENT);
    gl.vertexAttribPointer(fillLocation, 4, gl.SHORT, false, VEC_ATTR_LENGTH * Int16Array.BYTES_PER_ELEMENT, 5 * Int16Array.BYTES_PER_ELEMENT);
    gl.drawArrays(gl.TRIANGLES, 0, data.length / VEC_ATTR_LENGTH);
  }
  requestAnimationFrame(render);
}

setInterval(update, 1000/ANIMATION_TIMING);
// update();
// console.log(data);

document.body.appendChild(canvas);
gl.useProgram(shaderProgram);

requestAnimationFrame(render);

if(module.hot) {
  module.hot.accept();
  module.hot.dispose(() => {
    document.body.removeChild(canvas);
  });
}
