import './main.css';

const canvas = document.createElement('canvas');
const gl = canvas.getContext('webgl');

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
resizeCanvas();

document.body.appendChild(canvas);
window.addEventListener('resize', resizeCanvas, false);

if (gl) {
  gl.clearColor(0, 0, 0, 1);
  gl.clear(gl.COLOR_BUFFER_BIT);
}

if(module.hot) {
  module.hot.accept();
  module.hot.dispose(() => {
    document.body.removeChild(canvas);
  });
}
