part of wang_webgl;

void AddVector3ToArray(Vector3 vector, List<double> array) {
  array.add(vector.x);
  array.add(vector.y);
  array.add(vector.z);
}

class ScreenVertices extends WangObject {
  List<double> vertices;
  
  // Constructor
  ScreenVertices() :
    this.vertices = [1.0, 1.0,
                     -1.0, 1.0,
                     1.0, -1.0,
                     -1.0, -1.0],
    super() {
    List<String> names = ['screen_position'];
    List<String> types = ['VAP'];
    List<Object> objects = [vertices];
    memberDataNames = names;
    memberDataTypes = types;
    memberDataIndice = objects;
  }
  
  // Methods
  String GenerateDeclareShaderCode() {
    return null;    
  }
  
  String GenerateIntersectShaderCode() {
    return null;    
  }
  
  String GenerateMinimumIntersectShaderCode() {
    return null;    
  }
  
  String GenerateGetNormalShaderCode() {
    return null;    
  }
  
  String GenerateShadowTestCode() {
    return null;
  }
}

class WangCameraForPhotography extends WangObject {
  Vector3 cameraPosition;
  Vector3 cameraTarget;
  Vector3 cameraUp;
  Vector3 cameraLeft;
  Vector3 cameraDirection;
  List<double> frame;
  double perspective;
  double aspectRatio;
  double angleX;
  double angleY;
  
  // Constructor
  WangCameraForPhotography(this.cameraPosition, this.cameraTarget, this.cameraUp, this.perspective, this.aspectRatio) : 
    this.frame = new List(),
    this.angleX = 0.0,
    this.angleY = 0.0,
    super() {
    Update();
    List<String> names = ['camera_position', 'light_goal'];
    List<String> types = ['U3F', 'VAP'];
    List<Object> objects = [cameraPosition, frame];
    memberDataNames = names;
    memberDataTypes = types;
    memberDataIndice = objects;
  }
  
  // Method
  void Update() {
    RotateAroundPointXY();
    Normalize();
    SetCorners();
  }
  
  void Normalize() {
    cameraDirection = cameraTarget - cameraPosition;
    cameraDirection.normalize();
    cameraLeft = cameraDirection.cross(cameraUp);
    cameraLeft.normalize();
    cameraUp = cameraLeft.cross(cameraDirection);
    cameraUp.normalize();
  }
  
  void SetCorners() {
    var center = cameraPosition + cameraDirection * perspective;
    var camera_top_left = center + cameraUp - cameraLeft * aspectRatio;
    var camera_top_right = center + cameraUp + cameraLeft * aspectRatio;
    var camera_bottom_left = center - cameraUp - cameraLeft * aspectRatio;
    var camera_bottom_right = center - cameraUp + cameraLeft * aspectRatio;
    frame.clear();
    AddVector3ToArray(camera_top_left, frame);
    AddVector3ToArray(camera_top_right, frame);
    AddVector3ToArray(camera_bottom_left, frame);
    AddVector3ToArray(camera_bottom_right, frame);
  }
  
  void RotateAroundPointXY() {
    double distance = (cameraPosition - cameraTarget).length;
    cameraPosition.x = distance * -sin(angleX) * cos(angleY);
    cameraPosition.y = distance * -sin(angleY);
    cameraPosition.z = -distance* cos(angleX) * cos(angleY);
  }
  
  void CameraControl(KeyboardEvent key_event) {
    Matrix4 matrix = new Matrix4.identity();
    if(key_event.keyCode == KeyCode.W) {
      perspective += 0.5;
    } 
    else if(key_event.keyCode == KeyCode.S) {
      perspective -= 0.5;
    }
    else if(key_event.keyCode == KeyCode.UP) {
      angleY -= PI/72.0;
    }
    else if(key_event.keyCode == KeyCode.DOWN) {
      angleY += PI/72.0;
    } 
    else if(key_event.keyCode == KeyCode.RIGHT) {
      angleX -= PI/72.0;
    }
    else if(key_event.keyCode == KeyCode.LEFT) {
      angleX += PI/72.0;
    }
  }
  
  String GenerateDeclareShaderCode() {
    return null;    
  }
  
  String GenerateIntersectShaderCode() {
    return null;    
  }
  
  String GenerateMinimumIntersectShaderCode() {
    return null;    
  }
  
  String GenerateGetNormalShaderCode() {
    return null;    
  }
  
  String GenerateShadowTestCode() {
    return null;
  }
}

class WangSphere extends WangObject {
  Vector3 centerPosition;
  double sphereRadius;  
  String codePositionName;
  String codeRadiusName;
  String codeIntersectName;
  
  // Constructor
  WangSphere(this.centerPosition, this.sphereRadius) : super() {
    String ID = objectID.toString();
    codePositionName = 'sphere_center' + ID;
    codeRadiusName = 'sphere_radius' + ID;
    codeIntersectName = "sphere_intersect" + ID;
    List<String> names = [codePositionName, codeRadiusName];
    List<String> types = ['U3F', 'U1F'];
    List<Object> objects = [centerPosition, sphereRadius];  
    memberDataNames = names;
    memberDataTypes = types;
    memberDataIndice = objects;
  }
  
  String GenerateDeclareShaderCode() {
    String code =
        "uniform vec3 " + codePositionName + ";\n" +
        "uniform float " + codeRadiusName + ";\n";
    return code;
  }
  
  String GenerateIntersectShaderCode() {
    String code =
        "float " + codeIntersectName + " = IntersectSphere(" + codePositionName + ", " + codeRadiusName + ", source, ray);\n";
    return code;
  }
  
  String GenerateMinimumIntersectShaderCode() {
    String code =
        "if(" + codeIntersectName + " < closest)" + " closest = " + codeIntersectName + ";\n";
    return code;
  }
  
  String GenerateGetNormalShaderCode() {
    String code =
        "if(" + codeIntersectName + " == closest)" + " normal = GetNormalForSphere(hit_position, " + codePositionName + ", " + codeRadiusName +");\n";
    return code;
  }
  
  String GenerateShadowTestCode() {
    String code = GenerateIntersectShaderCode();
    code += "if(" + codeIntersectName + " < 1.0) return 0.3;\n";
    return code;
  }
}