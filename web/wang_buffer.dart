part of wang_webgl;

class WangBuffer {
  var data;
  var bufferID;
  var bufferType;
  WangBuffer(this.data ,gl.RenderingContext context, this.bufferType) {
    bufferID = context.createBuffer();
  }
  
  void BindBuffer(gl.RenderingContext context) {
    context.bindBuffer(bufferType, bufferID);
  }
  
  void CreateBuffer(gl.RenderingContext context, int usage) {
    context.bufferDataTyped(bufferType, data, usage);
  }
}
