//Texture mapping for 3D object inspired from Pdcxs: https://www.shadertoy.com/view/fdtcRM

#define TMIN 0.1
#define TMAX 20.
#define RAYMARCH_TIME 128
#define PRECISION .001
#define AA 3
#define PI 3.14159265

vec3 rotate3D(vec3 p, vec3 axis, float theta){

    // Normalize the axis vector
    axis = normalize(axis);
    
    // Calculate sine and cosine of the angle
    float cosAngle = cos(theta);
    float sinAngle = sin(theta);

    // Calculate rotation matrix elements
    float ux = axis.x;
    float uy = axis.y;
    float uz = axis.z;

    float m11 = cosAngle + ux * ux * (1. - cosAngle);
    float m12 = ux * uy * (1. - cosAngle) - uz * sinAngle;
    float m13 = ux * uz * (1. - cosAngle) + uy * sinAngle;

    float m21 = uy * ux * (1. - cosAngle) + uz * sinAngle;
    float m22 = cosAngle + uy * uy * (1. - cosAngle);
    float m23 = uy * uz * (1. - cosAngle) - ux * sinAngle;

    float m31 = uz * ux * (1. - cosAngle) - uy * sinAngle;
    float m32 = uz * uy * (1. - cosAngle) + ux * sinAngle;
    float m33 = cosAngle + uz * uz * (1. - cosAngle);

    // Apply the rotation matrix to the point
    float rotatedX = m11 * p.x + m12 * p.y + m13 * p.z;
    float rotatedY = m21 * p.x + m22 * p.y + m23 * p.z;
    float rotatedZ = m31 * p.x + m32 * p.y + m33 * p.z;

    // Update the point with the rotated values
    p.x = rotatedX;
    p.y = rotatedY;
    p.z = rotatedZ;

    return p;

}


vec2 fixUV(in vec2 c) {
    return (2. * c - iResolution.xy) / min(iResolution.x, iResolution.y);
}

float sdfRect(in vec3 p, vec3 b) { //http://iquilezles.org/articles/distfunctions/
    vec3 d = abs(p) - b;
    return length(max(d, 0.)) + min(max(max(d.x, d.y),d.z), 0.);
}

float sdCutHollowSphere( vec3 p, float r, float h, float t ){ //http://iquilezles.org/articles/distfunctions/
  // r = sphere's radius
  // h = cutting's plane's position
  // t = thickness  
  
  // sampling independent computations (only depend on shape)
  float w = sqrt(r*r-h*h);
  
  // sampling dependant computations
  vec2 q = vec2( length(p.xz), p.y );
  return ((h*q.x<w*q.y) ? length(q-vec2(w,h)) : 
                          abs(length(q)-r) ) - t;
}


//float sdPlane(vec3 p, vec3 dir, vec3 pt){ //not sure of the function
    ////return dot(p, normalize(dir)) + dot(pt, normalize(dir));
    //return dot(p+pt, normalize(dir));
//}

float map(in vec3 p) {
    //float d = sdfRect(p, vec3(.7)); //cube
    //float d1 = length(p) - 1.; //sphere
    float d = sdCutHollowSphere(rotate3D(p, vec3(0., 1., 1.), PI/4.), 1., 0.3, 0.1); //cut hollow sphere
    
    return d;
}

float rayMarch(in vec3 ro, in vec3 rd) {
    float t = TMIN;
    for(int i = 0; i < RAYMARCH_TIME && t < TMAX; i++) {
        vec3 p = ro + t * rd;
        float d = map(p);
        if(d < PRECISION)
            break;
        t += d;
    }
    return t;
}

// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, float tmin, float tmax, const float k )
{
	float res = 1.0;
    float t = tmin;
    for( int i=0; i<64; i++ )
    {
		float h = map( ro + rd*t );
        res = min( res, k*h/t );
        t += clamp( h, 0.01, 0.10 );
        if( res<0.002 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal(in vec3 p) {
    const float h = 0.0001;
    const vec2 k = vec2(1, -1);
    return normalize(k.xyy * map(p + k.xyy * h) +
        k.yyx * map(p + k.yyx * h) +
        k.yxy * map(p + k.yxy * h) +
        k.xxx * map(p + k.xxx * h));
}

mat3 setCamera(vec3 ta, vec3 ro, float cr) {
    vec3 z = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.);
    vec3 x = normalize(cross(z, cp));
    vec3 y = cross(x, z);
    return mat3(x, y, z);
}

vec3 render(vec2 uv) {
    vec3 color = vec3(0.);
    vec3 ro = vec3(2. * cos(iTime), 1., 2. * sin(iTime));
    if (iMouse.z > 0.01) {
        float theta = iMouse.x / iResolution.x * 2. * PI;
        ro = vec3(2. * cos(theta), 2. * (-2. * iMouse.y / iResolution.y + 1.), 2. * sin(theta));
    }
    vec3 ta = vec3(0.);
    mat3 cam = setCamera(ta, ro, 0.);
    vec3 rd = normalize(cam * vec3(uv, 1.));
    float t = rayMarch(ro, rd);
    if(t < TMAX) {
        vec3 p = ro + t * rd;
        vec3 n = calcNormal(p);
        vec3 light = vec3(2., 1., 0.);
        float dif = clamp(dot(normalize(light - p), n), 0., 1.);

        if( dif>0.001 ) dif *= calcSoftshadow( p+n*0.001, light, 0.001, 10.0, 0.6 );
                        
        float amb = 0.5 + 0.5 * dot(n, vec3(0., 2., 0.));

        vec3 shadows = amb * vec3(0.8) + dif * vec3(0.7);
        vec3 colorXY = texture(iChannel0, p.xy * .5 + .5).rgb;
        vec3 colorXZ = texture(iChannel0, p.xz * .5 + .5).rgb;
        vec3 colorYZ = texture(iChannel0, p.yz * .5 + .5).rgb;
        n = abs(n);
        n = pow(n, vec3(10.));
        n /= n.x + n.y + n.z;
        vec3 colorTexture = colorXY * n.z + colorXZ * n.y + colorYZ * n.x;
        //color = shadows; //shadows only
        //color = colorTexture; //texture without shadows
        color = colorTexture * shadows; //texture with shadows
        //color = n;
    }
    
    return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 color = vec3(0.);

    
    for(int m = 0; m < AA; m++) {
        for(int n = 0; n < AA; n++) {
            vec2 offset = 2. * (vec2(float(m), float(n)) / float(AA) - .5);
            vec2 uv = fixUV(fragCoord + offset);
            color += render(uv);
        }
    }
    
    vec2 uv2 = fragCoord.xy / iResolution.xy;
    dot(color, color)==0.? color = texture(iChannel1, uv2).rgb : color=color / float(AA * AA);
    
    //fragColor = vec4(color / float(AA * AA), 1.);
    fragColor = vec4(color, 1.);
    
}
