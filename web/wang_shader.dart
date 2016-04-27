part of wang_webgl;

class WangProgram {
  gl.Program program;
  
  WangProgram(gl.RenderingContext context) : program = context.createProgram(); 
  
  void AttachShader(gl.RenderingContext context, gl.Shader shader) {
    context.attachShader(program, shader);
  }
  
  void LinkProgram(gl.RenderingContext context) {
    context.linkProgram(program);
    if(!context.getProgramParameter(program, gl.LINK_STATUS)) {
      print(context.getProgramInfoLog(program));
      return;
    }
  }
  
  void UseProgram(gl.RenderingContext context) {
    context.useProgram(program);
  }
}

class WangShader {
  static var shaderTypeToken = {
    'VERTEX' : gl.RenderingContext.VERTEX_SHADER,
    'FRAGMENT' : gl.RenderingContext.FRAGMENT_SHADER
  };
  final String shaderCode;
  final int shaderType; 
  gl.Shader shader;
 
  // Constructor
  WangShader(this.shaderCode, shader_type) : shaderType = shaderTypeToken[shader_type];
  
  // Getter/Setter
  gl.Shader get GetShader => shader;
  
  // Method
  void CompileShader(gl.RenderingContext context) {
    shader = context.createShader(shaderType);
    context.shaderSource(shader, shaderCode);
    context.compileShader(shader);
    if(!context.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      print(context.getShaderInfoLog(shader));
      return;
    }
  }
}
