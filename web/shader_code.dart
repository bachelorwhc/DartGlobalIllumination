part of wang_webgl;

final String vertex_shader_code =
'''
attribute vec2 screen_position;
attribute vec3 light_goal;
varying vec3 goal_position;

void main(void) {
  gl_Position = vec4(screen_position, 1.0, 1.0);
  goal_position = light_goal;
}
''';

String MakeFragmentDeclare() {
  String fragment_shader_declare =
  '''
  precision highp float;
  const float FLT_MAX = 65536.0;
  const float EPSILON = 0.0001;
  '''
  +
  "const float ROOM_SIZE = " + Engine.roomSize.toString() + ";\n"
  +
  "const int TRACE_LEVEL = " + Engine.traceLevel.toString() + ";\n"
  +
  "const vec3 light_position = vec3(" + 
  Engine.lightX.toString() + ", " +
  Engine.lightY.toString() + ", " +
  Engine.lightZ.toString() + ");\n"
  +
  "const float light_power = " + Engine.lightPower.toString() + ";\n"
  +
  '''
  const vec3 room_cube_min = vec3(-ROOM_SIZE);
  const vec3 room_cube_max = vec3(ROOM_SIZE);
  varying vec3 goal_position;
  uniform vec3 camera_position;
  ''';
  return fragment_shader_declare;
}

final String fragment_shader_function =
'''
vec2 IntersectRoom(vec3 ray_source, vec3 ray) {
  vec3 intersect_min = (room_cube_min - ray_source) / ray;
  vec3 intersect_max = (room_cube_max - ray_source) / ray;
  vec3 intersect1 = min(intersect_min, intersect_max);
  vec3 intersect2 = max(intersect_min, intersect_max);
  float near = max(max(intersect1.x, intersect1.y), intersect1.z);
  float far = min(min(intersect2.x, intersect2.y), intersect2.z);
  return vec2(near, far);
}

vec3 GetNormalForRoom(vec3 hit) {
  if(hit.x < room_cube_min.x + EPSILON) return vec3(-1.0, 0.0, 0.0);
  else if(hit.x > room_cube_max.x - EPSILON) return vec3(1.0, 0.0, 0.0);
  else if(hit.y < room_cube_min.y + EPSILON) return vec3(0.0, -1.0, 0.0);
  else if(hit.y > room_cube_max.y - EPSILON) return vec3(0.0, 1.0, 0.0);
  else if(hit.z < room_cube_min.z + EPSILON) return vec3(0.0, 0.0, -1.0);
  else return vec3(0.0, 0.0, 1.0);
}

float IntersectSphere(vec3 sphere_position, float radius, vec3 ray_source, vec3 ray) {
  vec3 to_sphere = ray_source - sphere_position;
  normalize(ray);
  float a = dot(ray, ray);
  float b = 2.0 * dot(to_sphere, ray);
  float c = dot(to_sphere, to_sphere) - radius * radius;
  float discriminant = b * b - 4.0 * a * c;
  if(discriminant > 0.0) {
    float t = (-b - sqrt(discriminant))/ (2.0 * a);
    if(t > 0.0)
      return t;
  }
  return FLT_MAX;
}

vec3 GetNormalForSphere(vec3 hit_position, vec3 sphere_center, float sphere_radius) {
  return (hit_position - sphere_center) / sphere_radius;
}
''';

String MakeCaculateColor(List<WangObject> objects) {
  String intersect_code = '';
  for(int i = 0; i < objects.length; i++) {
    String temp = objects[i].GenerateIntersectShaderCode();
    intersect_code += temp;
  }
  
  String minimum_intersect_code = '';
  for(int i = 0; i < objects.length; i++) {
    String temp =  objects[i].GenerateMinimumIntersectShaderCode();
    minimum_intersect_code += temp;
  }
  
  String get_normal_code = '';
  for(int i = 0; i < objects.length; i++) {
    String temp = objects[i].GenerateGetNormalShaderCode();
    get_normal_code += temp;
  }
  
  String get_shadow_code = '';
  for(int i = 0; i < objects.length; i++) {
    String temp = objects[i].GenerateShadowTestCode();
    get_shadow_code += temp;
  }
  
  String wall_code = '';
  if(Engine.reflectWall)
    wall_code += "ray = reflect(ray, normal);";
  else 
    wall_code += "if(hit_position.x < -ROOM_SIZE + EPSILON) surface = vec3(0.1, 0.5, 1.0); else if(hit_position.x > ROOM_SIZE - EPSILON) surface = vec3(1.0, 0.9, 0.1);";
  
  String fragment_shader_caculate =
  '''
float GetShadow(vec3 source, vec3 ray) {
  '''
  +
  get_shadow_code
  +
  '''
  return 1.0;
}
  '''
  +
  '''
vec3 CaculateColor(vec3 source, vec3 goal, vec3 light) {
  vec3 ray = goal - source;
  vec3 color_mask = vec3(1.0);
  vec3 result_color = vec3(0.0);

  for(int level = 0; level < TRACE_LEVEL; level++) {
    vec2 intersect_room = IntersectRoom(source, ray);
  ''' 
  + 
  intersect_code
  +
  '''
    float closest = FLT_MAX;
    if(intersect_room.x < intersect_room.y) closest = intersect_room.y; 
  '''
  +
  minimum_intersect_code
  +
  '''
    normalize(ray);
    vec3 hit_position = source + closest * ray;
    vec3 normal;
    vec3 surface = vec3(0.75);
    float specular_light = 0.0;
    
    
    if(closest == intersect_room.y) {
      normal = -GetNormalForRoom(hit_position);
  '''
  +
  wall_code
  +
  '''
       
    }
    else if(closest == FLT_MAX)
      break;
    else {
  '''
  +
  get_normal_code
  +
  '''
      ray = reflect(ray, normal);
      vec3 reflected_light = normalize(reflect(light - hit_position, normal));
      specular_light = max(0.0, dot(reflected_light, normalize(hit_position - source)));
      specular_light = 2.0 * pow(specular_light, 20.0);
    }

    vec3 to_light = light - hit_position;
    float diffuse = max(0.0, dot(normalize(to_light), normal));
    float shadow_intensity = GetShadow(hit_position + normal * EPSILON, to_light); 
    color_mask *= surface;
    result_color += color_mask * (light_power * diffuse * shadow_intensity);
    result_color += color_mask * specular_light * shadow_intensity;
    source = hit_position;
  }

  return result_color;
}
  ''';
  return fragment_shader_caculate;
}

final String fragment_shader_main =
'''
void main(void) {
  gl_FragColor = vec4(CaculateColor(camera_position, goal_position, light_position), 1.0);
}
''';

String MakeFragmentShaderCode(List<WangObject> objects) {
  String fragment_shader_code = '';
  String declare_code = '';
  for(int i = 0; i < objects.length; i++) {
    String temp = objects[i].GenerateDeclareShaderCode();
    declare_code += temp;
  }
  fragment_shader_code += MakeFragmentDeclare();
  fragment_shader_code += declare_code;
  fragment_shader_code += fragment_shader_function;
  String caculate_code = MakeCaculateColor(objects);
  fragment_shader_code += caculate_code;
  fragment_shader_code += fragment_shader_main;
  return fragment_shader_code; 
}
