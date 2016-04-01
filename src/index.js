import './main.css';
import vertexShader from './shaders/bezier.v.glsl';
import fragmentShader from './shaders/bezier.f.glsl';
import createProgram from './shaders/createProgram';

function resizeCanvas() {
  let displayWidth  = canvas.clientWidth;
  let displayHeight = canvas.clientHeight;
  if (canvas.width  != displayWidth ||
      canvas.height != displayHeight) {
    canvas.width  = displayWidth;
    canvas.height = displayHeight;
    gl.viewport(0, 0, displayWidth, displayHeight);
  }
}

const canvas = document.createElement('canvas');
const gl = canvas.getContext('webgl');

document.body.appendChild(canvas);
window.addEventListener('resize', resizeCanvas, false);
resizeCanvas(canvas, gl);
const shaderProgram = createProgram(gl, vertexShader, fragmentShader);
gl.useProgram(shaderProgram);

const positionLocation = gl.getAttribLocation(shaderProgram, 'position');

// Create a buffer and put a single clipspace rectangle in
// it (2 triangles)
const buffer = gl.createBuffer();


function render() {
  gl.clearColor(0, 0, 0, 1);
  gl.clear(gl.COLOR_BUFFER_BIT);

  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
     -0.5, 0, 0,
      0.5, 0, 0,
      0, 0.5, 0
  ]), gl.STATIC_DRAW);

  gl.enableVertexAttribArray(positionLocation);
  gl.vertexAttribPointer(positionLocation, 3, gl.FLOAT, false, 0, 0);
  gl.drawArrays(gl.TRIANGLES, 0, 3);
}

setInterval(render, 1000/30);

if(module.hot) {
  module.hot.accept();
  module.hot.dispose(() => {
    document.body.removeChild(canvas);
  });
}
