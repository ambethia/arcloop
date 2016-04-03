const createShader = (gl, shaderSource, shaderType) => {
  let shader = gl.createShader(shaderType);
  gl.shaderSource(shader, shaderSource);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS))
    console.error('Error creating shader:', gl.getShaderInfoLog(shader));

  return shader;
}

const createProgram = (gl, vertexShaderSource, fragmentShaderSource) => {
  let vertexShader = createShader(gl, vertexShaderSource, gl.VERTEX_SHADER);
  let fragmentShader = createShader(gl, fragmentShaderSource, gl.FRAGMENT_SHADER);

  let program = gl.createProgram();
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS))
    console.error('Error creating shader program:', gl.getProgramInfoLog(program));

  return program;
}

export default createProgram;
