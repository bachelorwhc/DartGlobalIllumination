part of wang_webgl;

class ShaderVariable {
  static Map<String, int> _shaderVariableType = {
    'U1F' : 0, 'U1FV' : 1, 'U1I' : 2, 'U1IV' : 3,
    'U2F' : 4, 'U2FV' : 5, 'U2I' : 6, 'U2IV' : 7,
    'U3F' : 8, 'U3FV' : 9, 'U3I' : 10, 'U3IV' : 11,
    'U4F' : 12, 'U4FV' : 13, 'U4I' : 14, 'U4IV' : 15,
    'UM2FV' : 16, 'UM3FV' : 17, 'UM4FV' : 18,
    'VA1F' : 19, 'VA1FV' : 20,
    'VA2F' : 21, 'VA2FV' : 22,
    'VA3F' : 23, 'VA3FV' : 24,
    'VA4F' : 25, 'VA4FV' : 26,
    'VAP' : 27
  };
  
  String _variableName;
  int _variableType;
  bool _haveName;
  bool _haveType;
  
  // Optional variable
  int bufferType;
  
  // Constructor
  ShaderVariable() : this._haveName = false, this._haveType = false; 
  
  // Methods
  gl.UniformLocation GetUniformLocation(gl.RenderingContext context, WangProgram shader_program) {
    if(!_haveName) {
      print("This object hasn't been initialized.");
      return null;
    }
    return context.getUniformLocation(shader_program.program, _variableName);    
  }
  
  int GetAttributeLocation(gl.RenderingContext context, WangProgram shader_program) {
    if(!_haveName) {
      print("This object hasn't been initialized.");
      return null;
    }
    var location = context.getAttribLocation(shader_program.program, _variableName);
    if(location < 0)
      return null;
    context.enableVertexAttribArray(location);
    return location;
  }
  
  void CreateBuffer(gl.RenderingContext context, int buffer_type) {
    var buffer = context.createBuffer();
    bufferType = buffer_type;
    context.bindBuffer(bufferType, buffer);
  }
  
  void SetBufferData(gl.RenderingContext context, List<Object> array, int usage) {
    context.bufferDataTyped(bufferType, new Float32List.fromList(array), usage);
  }
  
  void SetAttributePointer(gl.RenderingContext context, int location, int size, int type, bool normalized, int stride, int offset) {
    context.vertexAttribPointer(location, size, type, normalized, stride, offset);
  }
  
  void SetUniformVariable(gl.RenderingContext context, gl.UniformLocation location, dynamic variable) {
    if(!_haveType) {
      print("This object hasn't been initialized.");
      return;
    }
    
    switch(_variableType) {
      case 0:
        context.uniform1f(location, variable);
        break;
      case 1:
        context.uniform1fv(location, variable);
        break;
      case 2:
        context.uniform1i(location, variable);
        break;
      case 3:
        context.uniform1iv(location, variable);
        break;
      case 4:
        context.uniform2f(location, variable.x, variable.y);
        break;
      case 5:
        context.uniform2fv(location, variable);
        break;
      case 6:
        context.uniform2i(location, variable.x, variable.y);
        break;
      case 7:
        context.uniform2iv(location, variable);
        break;
      case 8:
        context.uniform3f(location, variable.x, variable.y, variable.z);
        break;
      case 9:
        context.uniform3fv(location, variable);
        break;
      case 10:
        context.uniform3i(location, variable.x, variable.y, variable.z);
        break;
      case 11:
        context.uniform3iv(location, variable);
        break;
      case 12:
        context.uniform4f(location, variable.x, variable.y, variable.z, variable.w);
        break;
      case 13:
        context.uniform4fv(location, variable);
        break;
      case 14:
        context.uniform4i(location, variable.x, variable.y, variable.z, variable.w);
        break;
      case 15:
        context.uniform4iv(location, variable);
        break;
      case 16:
        context.uniformMatrix2fv(location, false, variable);
        break;
      case 17:
        context.uniformMatrix3fv(location, false, variable);
        break;
      case 18:
        context.uniformMatrix4fv(location, false, variable);
        break;
    }
    return;
  }
  
  void SetAttributeVariable(gl.RenderingContext context, int location, dynamic variable) {
    if(!_haveType) {
      print("This object hasn't been initialized.");
      return;
    }
    
    switch(_variableType) {
      case 19:
        context.vertexAttrib1f(location, variable);
        break;
      case 20:
        context.vertexAttrib1fv(location, variable);
        break;
      case 21:
        context.vertexAttrib2f(location, variable.x, variable.y);
        break;
      case 22:
        context.vertexAttrib2fv(location, variable);
        break;
      case 23:
        context.vertexAttrib3f(location, variable.x, variable.y, variable.z);
        break;
      case 24:
        context.vertexAttrib3fv(location, variable);
        break;
      case 25:
        context.vertexAttrib4f(location, variable.x, variable.y, variable.z, variable.w);
        break;
      case 26:
        context.vertexAttrib4fv(location, variable);
        break;
    }
    return;
  }
  
  set variableName(String name) {
    _haveName = true;
    _variableName = name;
  }
  
  set variableType(String type) {
    if(!_shaderVariableType.containsKey(type))
      return;
    _haveType = true;
    _variableType = _shaderVariableType[type];
  }
}

abstract class WangObject {
  static int nextObjectID = 0;
  
  Map<String, gl.UniformLocation> UniformLocations;
  Map<String, int> AttributeLocations;
  Map<String, ShaderVariable> _shaderObjects;
  Map<String, Object> memberDatas;
  List<String> shaderVariableNames;
  bool _svnInitialized;
  List<String> shaderVariableTypes;
  bool _svtInitialized;
  int objectID;
  
  // Constructor
  WangObject() :
    this.UniformLocations = new Map(),
    this.AttributeLocations = new Map(),    
    this._shaderObjects = new Map(),
    this.memberDatas = new Map(),
    this._svnInitialized = false,
    this._svtInitialized = false,
    this.objectID = nextObjectID++;
  
  // Methods
  void SetLocaitons(gl.RenderingContext context, WangProgram shader_program) {
    if(!(_svnInitialized && _svtInitialized)) {
      print("Shader variable lists are not initialized.");
      return;
    }
    
    if(shaderVariableNames.length != shaderVariableTypes.length) {
      print("Lists are not matches.");
      return;
    }
    
    for(int i = 0; i < shaderVariableNames.length; i++) {
      var name = shaderVariableNames[i];
      _shaderObjects.putIfAbsent(name, () => new ShaderVariable());
      _shaderObjects[name].variableName = name;
      _shaderObjects[name].variableType = shaderVariableTypes[i];
      
      var temp_location; 
      var type = shaderVariableTypes[i];
      if(type[0] == 'U')
        temp_location = _shaderObjects[name].GetUniformLocation(context, shader_program);
      else if(type[0] == 'V')
        temp_location = _shaderObjects[name].GetAttributeLocation(context, shader_program);
      
      if(temp_location == null)
      {
        print(name+" is not in shader program or variable type is wrong, please check your variable list.");
        print(name);
        print(shaderVariableTypes[i]);
      }
      
      if(temp_location is gl.UniformLocation)
        UniformLocations[name] = temp_location;
      else
        AttributeLocations[name] = temp_location;
    }
  }
  
  void CreateBuffer(gl.RenderingContext context, String name, int buffer_type) {
    _shaderObjects[name].CreateBuffer(context, buffer_type);
  }
  
  void SetBufferData(gl.RenderingContext context, String name, int usage) {
    var array = memberDatas[name];
    _shaderObjects[name].SetBufferData(context, array, usage);
  }
  
  void SetAttributePointer(gl.RenderingContext context, String name, int size, int type, bool normalized, int stride, int offset) {
    var location = AttributeLocations[name];
    context.vertexAttribPointer(location, size, type, normalized, stride, offset);
  }
  
  void UpdateShaderValue(gl.RenderingContext context) {
    if(!_svtInitialized) {
      print("UpdateShaderValue should be used after variable qualifiers are initialized.");
      return;
    }
    for(int i = 0; i < shaderVariableNames.length; i++) {
      var name = shaderVariableNames[i];
      var type = shaderVariableTypes[i];
      if(type == 'VAP')
        continue;
      if(type[0] == 'U') {
        _shaderObjects[name].SetUniformVariable(context, UniformLocations[name], memberDatas[name]);
      }
      else if(type[0] == 'V') {
        _shaderObjects[name].SetAttributeVariable(context, AttributeLocations[name], memberDatas[name]);
      }
    }
  }
  
  String GenerateDeclareShaderCode();
  
  String GenerateIntersectShaderCode();
  
  String GenerateMinimumIntersectShaderCode();
  
  String GenerateGetNormalShaderCode();
  
  String GenerateShadowTestCode();
  
  set memberDataIndice(List<Object> objects) {
    if(!_svnInitialized) {
      print("Shader variable lists are not initialized.");
      return;
    }
    
    if(objects.length != shaderVariableNames.length) {
      print("Lists are not matches.");
      return;
    }
    
    for(int i = 0; i < objects.length; i++) {
      memberDatas[shaderVariableNames[i]] = objects[i];
    }
  }
  
  set memberDataNames(List<String> names) {
    shaderVariableNames = new List.from(names);
    _svnInitialized = true;
  }
  
  set memberDataTypes(List<String> types) {
    shaderVariableTypes = new List.from(types);
    _svtInitialized = true;
  }
}