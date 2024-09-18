//Initial shader used to create this shader: https://www.shadertoy.com/view/ll33Wn
//Shader modified for step by step tutorial purpose

#define EPSILON 0.00001
#define MAX_STEPS 500
#define MIN_DIST 0.0
#define MAX_DIST 35.0

float cylinder(vec3 p, float r, float h) //https://iquilezles.org/articles/distfunctions/
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
    
}

float SceneSDF(vec3 p)
{
    float d = 0.;
    float d1 = cylinder(p, 3., 1.5);
    d = d1;
    
    return d;
    
}

float March(vec3 origin, vec3 direction, float start, float stop)
{
    float depth = start;
    
    for	(int i = 0; i < MAX_STEPS; i++)
    {
        float dist = SceneSDF(origin + (depth * direction)); // Grab min step
        
        if (dist < EPSILON) // Hit
            return depth;        
        
        depth += dist; // Step
        
        if (depth >= stop) // Reached max
            break;
    }
    
    return stop;
}

vec3 RayDirection(float fov, vec2 size, vec2 fragCoord)
{
    vec2 xy = fragCoord - (size / 2.0);
    float z = size.y / tan(radians(fov) / 2.0);
    return normalize(vec3(xy, -z));
}

mat4 LookAt(vec3 camera, vec3 target, vec3 up)
{
    vec3 f = normalize(target - camera);
    vec3 s = cross(f, up);
    vec3 u = cross(s, f);
    
    return mat4(vec4(s, 0.0),
        		vec4(u, 0.0),
        		vec4(-f, 0.0),
        		vec4(0.0, 0.0, 0.0, 1));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 viewDir = RayDirection(45.0, iResolution.xy, fragCoord);
    
    vec3 origin = vec3(15.,8.,15.);
    vec3 camNormal = vec3(0., 1., 0.); 
    vec3 camTarget = vec3(0.);   
       
    mat4 viewTransform = LookAt(origin, camTarget, camNormal);
    viewDir = (viewTransform * vec4(viewDir, 0.0)).xyz;
    
    float dist = March(origin, viewDir, MIN_DIST, MAX_DIST);
    
    if (dist > MAX_DIST) // No hit
    {
        vec3 backgroundCol = vec3(0.8);
                   
        fragColor = vec4(backgroundCol, 1.);
        
        return;
    }
       
    vec3 color = vec3(dist/50.);   
    
    fragColor = vec4(color, 1.0);
}