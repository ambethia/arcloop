import './main.css';
import vertexShader from './shaders/bezier.v.glsl';
import fragmentShader from './shaders/bezier.f.glsl';
import aaFragmentShader from './shaders/bezier-aa.f.glsl';
import createProgram from './shaders/createProgram';

import simple from '../test/simple.json';

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
const VEC_ATTR_LENGTH = 8;
const canvas = document.createElement('canvas');
const gl = canvas.getContext('webgl');
const aaEnabled = gl.getExtension('OES_standard_derivatives') != -1;
// gl.enable(gl.DEPTH_TEST);
gl.enable(gl.BLEND);
gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
const shaderProgram = createProgram(gl, vertexShader, aaEnabled ? aaFragmentShader : fragmentShader);
const positionLocation = gl.getAttribLocation(shaderProgram, 'position');
const fillLocation = gl.getAttribLocation(shaderProgram, 'fill');
const buffer = gl.createBuffer();
const viewMatrix = mat4.create();
const projectionMatrix = mat4.create();
const viewLocation = gl.getUniformLocation(shaderProgram, "view");
const projectionLocation = gl.getUniformLocation(shaderProgram, "projection");

let frameDelta = 0;
let globalFrame = 0;
let data = [];

function update() {
  let i = globalFrame % simple.animations["simple"].frames.length;
  let f = simple.animations["simple"].frames[i];
  data = simple.shapes[f].reduce((shapes, shape, d) => {
    let [r, g, b, a] = shape.fill;
    return shapes.concat(shape.curves.reduce((curves, curve) => {
      return curves.concat([
        curve[0][0], curve[0][1], -d, 0, r, g, b, a,
        curve[1][0], curve[1][1], -d, 1, r, g, b, a,
        curve[2][0], curve[2][1], -d, 2, r, g, b, a,
      ]);
    }, []));
  }, []);
  globalFrame++;
}

function render() {
  resizeCanvas();

  gl.clearColor(1, 1, 1, 1);
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

  if (data.length > 0) {
    gl.uniformMatrix4fv(viewLocation, false, viewMatrix);
    gl.uniformMatrix4fv(projectionLocation, false, projectionMatrix);
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data), gl.STATIC_DRAW);
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(positionLocation, 4, gl.FLOAT, false, VEC_ATTR_LENGTH * Float32Array.BYTES_PER_ELEMENT, 0);
    gl.enableVertexAttribArray(fillLocation);
    gl.vertexAttribPointer(fillLocation, 4, gl.FLOAT, false, VEC_ATTR_LENGTH * Float32Array.BYTES_PER_ELEMENT, 4 * Float32Array.BYTES_PER_ELEMENT);
    gl.drawArrays(gl.TRIANGLES, 0, data.length / VEC_ATTR_LENGTH);
  }
  requestAnimationFrame(render);
}

setInterval(update, 1000/ANIMATION_TIMING);

document.body.appendChild(canvas);
gl.useProgram(shaderProgram);

requestAnimationFrame(render);

if(module.hot) {
  module.hot.accept();
  module.hot.dispose(() => {
    document.body.removeChild(canvas);
  });
}
