library wang_webgl;

import 'dart:math';
import 'dart:typed_data';
import 'dart:html';
import 'dart:web_gl' as gl;
import 'package:vector_math/vector_math.dart';

part 'wang_object.dart';
part 'wang_buffer.dart';
part 'wang_shader.dart';
part 'wang_gi_objects.dart';
part 'shader_code.dart';

const int MAX_SPHERE_NUM = 45;
var Engine;

class WangGL {
  CanvasElement canvas;
  gl.RenderingContext context;
  WangProgram shaderProgram;
  double timer;
  int displayID;
  int displayWidth;
  int displayHeight;
  int sceneSphereNumber;
  int traceLevel;
  double roomSize;
  double lightPower;
  double lightX;
  double lightY;
  double lightZ;
  bool reflectWall;
  double FPS;
  var lastTime;
  List<Vector3> spawn_vectors;
  List<WangSphere> spheres;
  
  WangCameraForPhotography camera;
  ScreenVertices viewportDisplayVertices;
  
  // Constructor
  WangGL(String canvas_id) : 
    this.timer = 0.0, 
    this.sceneSphereNumber = 0,
    this.traceLevel = 3,
    this.displayID = 0,
    this.lightPower = 0.5,
    this.roomSize = 6.0,
    this.lightX = 3.0,
    this.lightY = 3.0,
    this.lightZ = 3.0,
    this.reflectWall = false,
    this.FPS = 0.0 {
    spheres = new List();
    spawn_vectors = SetSpawnedSphere();
    GenerateSphereFlake(spheres, spawn_vectors, 2, new Vector3(0.0, 0.0, 0.0), 3.0, new Vector3(0.0, 1.0, 0.0), 1.0/3.0);
    if(canvas_id == null)
      return;
    if(canvas_id[0]=='#')
      canvas = querySelector(canvas_id);
    else {
      String canvas_id_correct = '#' + canvas_id;
      canvas = querySelector(canvas_id_correct);
    }
    
    displayWidth = canvas.width;
    displayHeight= canvas.height;
    context = canvas.getContext3d();
    context.disable(gl.BLEND);
    context.viewport(0, 0, displayWidth, displayHeight);
    context.clearColor(0.0, 0.0, 0.0, 1.0);
    context.clearDepth(1.0);
    camera = new WangCameraForPhotography(
        new Vector3(18.0, 10.0, 18.0), new Vector3(0.0, 0.0, 0.0), new Vector3(0.0, 1.0, 0.0), 6.0, displayWidth/displayHeight);
    viewportDisplayVertices = new ScreenVertices();
    lastTime = new DateTime.now().millisecond;
  }
  
  // Method
  // Draw Scene
  void HandleInput() {
    document.onKeyDown.listen(camera.CameraControl);
    document.onKeyDown.listen(SceneControlHandle);
  }
  
  void SceneControlHandle(KeyboardEvent key_event) {
    if(key_event.keyCode == KeyCode.Z) {
      if(sceneSphereNumber > 0)
        --sceneSphereNumber;
      ResetContext();
    } 
    else if(key_event.keyCode == KeyCode.X) {
      if(sceneSphereNumber < MAX_SPHERE_NUM)
        ++sceneSphereNumber;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.C) {
      sceneSphereNumber = 0;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.V) {
      sceneSphereNumber = MAX_SPHERE_NUM;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.R) {
      traceLevel++;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.F) {
      if(traceLevel > 0)
        traceLevel--;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.T) {
      if(lightPower <= 2.0)
        lightPower += 0.05;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.G) {
      if(lightPower >= 0.01)
        lightPower -= 0.05;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.Y) {
      roomSize += 0.05;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.H) {
      if(roomSize >= 3.0)
        roomSize -= 0.05;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.I) {
      lightZ += 1.0;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.K) {
      lightZ -= 1.0;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.J) {
      lightX -= 1.0;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.L) {
      lightX += 1.0;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.U) {
      lightY += 1.0;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.O) {
      lightX -= 1.0;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.N) {
      reflectWall = true;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.M) {
      reflectWall = false;
      ResetContext();
    }
    else if(key_event.keyCode == KeyCode.B) {
      this.sceneSphereNumber = 0;
      this.traceLevel = 3;
      this.displayID = 0;
      this.lightPower = 0.5;
      this.roomSize = 6.0;
      this.lightX = 3.0;
      this.lightY = 3.0;
      this.lightZ = 3.0;
      ResetContext();
    }
  }
  
  void RemoveSphere(MouseEvent click_event) {
    if(sceneSphereNumber > 0)
      --sceneSphereNumber;
    ResetContext();
  }
  
  void AddSphere(MouseEvent click_event) {
    if(sceneSphereNumber < MAX_SPHERE_NUM)
      ++sceneSphereNumber;
    ResetContext();
  }
  
  void StartContext() {
    window.cancelAnimationFrame(displayID);
    ResetContext();
    HandleInput();
    Tick(timer);
  }
  
  void ResetContext() {
    Element level_display = querySelector('#trace_level');
    level_display.innerHtml = "<b>LEVEL : " + traceLevel.toString() + "</b>";
    List<WangSphere> spheres_test = new List();
    for(int i = 0; i < sceneSphereNumber; i++)
      spheres_test.add(spheres[i]);
    SetShaderProgramFromCodename(vertex_shader_code, MakeFragmentShaderCode(spheres_test));  
    
    for(int i = 0; i < spheres_test.length; i++) {
      spheres_test[i].SetLocaitons(context, shaderProgram);
      spheres_test[i].UpdateShaderValue(context);
    }
    PrepareDisplay();
  }
  
  void PrepareDisplay() {
    viewportDisplayVertices.SetLocaitons(context, shaderProgram);
    viewportDisplayVertices.CreateBuffer(context, 'screen_position', gl.ARRAY_BUFFER);
    viewportDisplayVertices.SetBufferData(context, 'screen_position', gl.STATIC_DRAW);
    viewportDisplayVertices.SetAttributePointer(context, 'screen_position', 2, gl.FLOAT, false, 0, 0);
    camera.SetLocaitons(context, shaderProgram);
    camera.CreateBuffer(context, 'light_goal', gl.ARRAY_BUFFER);    
    camera.SetAttributePointer(context, 'light_goal', 3, gl.FLOAT, false, 0, 0);
  }
  
  void Update(double t) {
    camera.Update();
    camera.UpdateShaderValue(context);
    camera.SetBufferData(context, 'light_goal', gl.STATIC_DRAW);
  }
  
  void Tick(double timer) {
    displayID = window.requestAnimationFrame(Tick);
    double delta = (1000/(new DateTime.now().millisecondsSinceEpoch - lastTime)).toDouble();
    lastTime = new DateTime.now().millisecondsSinceEpoch;
    String fps_str = delta.toString();
    String fps_diplay_str = '';
    for(int i = 0; i < 2; i++)
      fps_diplay_str += fps_str[i]; 
    Element fps_display = querySelector('#FPS');
    fps_display.innerHtml = "<b>FPS : " + fps_diplay_str + "</b>";
    Update(timer);
    DrawScene();
  }
  
  void DrawScene() {
    context.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    context.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    context.flush();
  }
  
  void SetShaderProgramFromCodename(String vertex_shader_code, String fragment_shader_code) {
    shaderProgram = new WangProgram(context);
    var vertex_shader = new WangShader(vertex_shader_code, 'VERTEX');
    var fragment_shader = new WangShader(fragment_shader_code, 'FRAGMENT');
    vertex_shader.CompileShader(context);
    fragment_shader.CompileShader(context);
    shaderProgram.AttachShader(context, vertex_shader.shader);
    shaderProgram.AttachShader(context, fragment_shader.shader);
    shaderProgram.LinkProgram(context);
    shaderProgram.UseProgram(context);
  }
  
  void SetShaderProgramFromShader(WangShader vertex_shader, WangShader fragment_shader) {
    shaderProgram.AttachShader(context, vertex_shader.shader);
    shaderProgram.AttachShader(context, fragment_shader.shader);
    shaderProgram.LinkProgram(context);
    shaderProgram.UseProgram(context);
  }
}

List<Vector3> SetSpawnedSphere() {
  const int spawn_base = 3;
  List<Vector3> nine_vectors = new List();
  
  List<Vector4> trios = new List();
  Vector3 axis = new Vector3(1.0, -1.0, 0.0).normalize();
  Vector4 temp = new Vector4.zero();
  double distance = 1.0/ sqrt(2.0);
  double angle = asin(2.0/sqrt(6.0));
  Matrix4 matrix = new Matrix4.identity().rotate(axis, angle);
  trios.add(new Vector4(distance, distance, 0.0, 0.0));
  trios.add(new Vector4(distance, 0.0, -distance, 0.0));
  trios.add(new Vector4(0.0, distance, -distance, 0.0));
  
  for(int i = 0; i < spawn_base; i++) {
    temp = matrix * trios[i];
    trios[i] = temp;
  }
  
  for(int i = 0; i < spawn_base; i++) {
    Vector3 zaxis = new Vector3(0.0, 0.0, 1.0);
    angle = i * 2.0 * PI / 3.0;
    matrix.setRotationZ(angle);
    for(int j = 0; j < spawn_base; j++) {
      var spawn4 = matrix * trios[j];
      var spawn3 = new Vector3(spawn4.x, spawn4.y, spawn4.z);
      nine_vectors.add(spawn3);
    }
  }
  return nine_vectors;
}

void GenerateSphereFlake(List<WangSphere> sphere_list, List<Vector3> nine_vectors, 
                         int depth, Vector3 center_position, double radius ,Vector3 direction, double scale) {
  const int spawn = 9;
  Vector3 axis = new Vector3.zero();
  Vector4 temp = new Vector4.zero();
  Matrix4 matrix;
  double angle;
  
  sphere_list.add(new WangSphere(center_position, radius));
  if(depth > 0) {
    depth--;
    Vector3 next_center;
    Vector3 next_direction;
    double next_radius;
    if(direction.z >= 1.0) {
      matrix = new Matrix4.identity();
    }
    else if(direction.z <= -1.0){
      Vector3 yaxis = new Vector3(0.0, 1.0, 0.0);
      matrix = new Matrix4.identity();
      matrix.setRotationY(PI);
    }
    else {
      Vector3 zaxis = new Vector3(0.0, 0.0, 1.0);
      axis = zaxis.cross(direction);
      axis.normalize();
      angle = acos(zaxis.dot(direction));
      matrix = new Matrix4.identity().rotate(axis, angle);
    }
    
    double offset = radius * (1.0 + scale);
    
    for(int i = 0; i < spawn; i++) {
      next_center = matrix * nine_vectors[i];
      next_center = next_center * offset + center_position;
      next_radius = radius * scale;
      next_direction = next_center - center_position;
      next_direction = next_direction / offset;
      GenerateSphereFlake(sphere_list, nine_vectors, depth, next_center, next_radius, next_direction, scale);
    }
  }
}

void main() {
  Engine = new WangGL("display_canvas");
  Engine.StartContext();
  return;
}
