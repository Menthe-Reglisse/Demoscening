// Inspired from Kishimisu tutorial: https://www.youtube.com/watch?v=khblXafu7iA
// Added additionnal forms features from Unigo Quilez website: https://iquilezles.org/articles/distfunctions/
// Shades lightning (normals and diffusion) and distorsion removal inspired from Reinder: https://www.shadertoy.com/view/4dSBz3 (tutorial: https://www.shadertoy.com/view/4dSfRc)
// Coloring inspired from Inspirnathan: https://www.shadertoy.com/view/fdjGRD (https://inspirnathan.com/posts/54-shadertoy-tutorial-part-8/)
// Toon shading inspired from Inspirnathan: https://www.shadertoy.com/view/sd2GDD

float pi = 3.14159;

float max3(vec3 p){ // maximum element of a 3D vector
    return max(max(p.x, p.y), p.z);
}

vec2 vectRot(vec2 vectIni, float rotAngle){

    mat2 matRot= mat2(cos(rotAngle), sin(rotAngle),-sin(rotAngle), cos(rotAngle));
    return matRot*vectIni;

}

struct Element {
    float sd; //signed distance
    vec3 col; //color
};

float sd_sphere(vec3 p, float r) { //r is sphere radius
    return length(p) - r;
}

float sd_cube(vec3 p, float lon) { //lon is cube diagonal half size
    vec3 q = abs(p)-lon;
    return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}


float sd_octahedron( vec3 p, float s){
  p = abs(p);
  float m = p.x+p.y+p.z-s;
  vec3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;
    
  float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
  return length(vec3(q.x,q.y-s+k,q.z-k)); 
}


Element minElement(Element elem_1, Element elem_2){
 if (elem_1.sd < elem_2.sd){
    return elem_1;
 }else{
    return elem_2;
 };

}

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


Element scene(vec3 p){

    Element res = Element(1.,vec3(1.));

    vec3 spherePos = vec3 (0., 0. ,-5.) + vec3(6.*cos(iTime*2.*pi*1./8.), 0., 0.);
    float sphere_sd = sd_sphere(p - spherePos, 1.);
    vec3 sphere_col = vec3(0.2, 0.9, 0.3);
    Element sphere = Element(sphere_sd, sphere_col);   
    res=sphere;
    
    vec3 cubePos = vec3 (1.5, 0.5, -3.);
    vec3 cubeRotAxis = vec3 (1., 1., 1.);
    float cubeRotAngle = iTime*2.*pi*0.2;
    float cube_sd = sd_cube(rotate3D(p - cubePos, cubeRotAxis, cubeRotAngle), sqrt(3.)/2.);
    vec3 cube_col = vec3(0.2, 0.3, 0.8);
    Element cube = Element(cube_sd, cube_col);
    res=minElement(res, cube);
    
    vec3 octaPos = vec3 (-1., 0.5, -1.5) + vec3(0., 0., -8.*abs(cos(iTime*2.*pi*1./8. + 2.*pi/4.)));
    vec3 octaRotAxis = vec3 (0., 1., 0.);
    float octaRotAngle = iTime*2.*pi*0.2;
    float octa_sd = sd_octahedron(rotate3D(p - octaPos, octaRotAxis, octaRotAngle), 0.7);
    vec3 octa_col = vec3(0.937, 0.780, 0.271);
    Element octa = Element(octa_sd, octa_col);
    res=minElement(res, octa);    
    
    float groundPos = -1.;
    float ground_sd = p.y - groundPos;
    vec3 ground_col = (0.6 + 0.4*mod(floor(p.x) + floor(p.z), 2.0)) * vec3(1., 0.05, 0.2); //tiled grid
    Element ground = Element(ground_sd, ground_col);    
    res=minElement(res, ground);
      
    return res;

}

vec3 calcNormal(in vec3 p) { //average normal direction from 4 approximated normals using the distance field and in 4 uniformly distributed directions (as vectors from the center of a cube to its corners so that they form a tetrahedron)
    vec2 e = vec2(1.0, -1.0) * 0.0005;
    return normalize(
        e.xyy * scene(p + e.xyy).sd +
        e.yyx * scene(p + e.yyx).sd +
        e.yxy * scene(p + e.yxy).sd +
        e.xxx * scene(p + e.xxx).sd);
}

vec3 rgb2hsv(vec3 rgb) { //normalized rgb into normalized hsv

    float r = rgb.x;
    float g = rgb.y;
    float b = rgb.z;
    
    float cmax = max(r, max(g, b));
    float cmin = min(r, min(g, b));
    float delta = cmax - cmin;

    float h = 0.0;
    if (delta != 0.0) {
        if (cmax == r) {
            h = mod((g - b) / delta, 6.)/6.;
        } else if (cmax == g) {
            h = ((b - r) / delta + 2.)/6.;
        } else if (cmax == b) {
            h = ((r - g) / delta + 4.)/6.;
        }
    }

    float s = (cmax != 0.0) ? (delta / cmax) : 0.0;
    float v = cmax;

    return vec3(h, s, v);

}

vec3 hsv2rgb(vec3 hsv) { //normalized hsv into normalized rgb

    float h = hsv.x * 360.;
    float s = hsv.y;
    float v = hsv.z;
    
    float c = v * s;
    float x = c * (1.0 - abs(mod(h / 60.0, 2.0) - 1.0));
    float m = v - c;

    vec3 rgb = vec3(0.0);

    if (h < 60.0) {
        rgb = vec3(c, x, 0.0);
    } else if (h < 120.0) {
        rgb = vec3(x, c, 0.0);
    } else if (h < 180.0) {
        rgb = vec3(0.0, c, x);
    } else if (h < 240.0) {
        rgb = vec3(0.0, x, c);
    } else if (h < 300.0) {
        rgb = vec3(x, 0.0, c);
    } else {
        rgb = vec3(c, 0.0, x);
    }

    return rgb + m;

}

vec3 make_rgb_pastel(vec3 rgb, float saturationMultCoeff){//normalized rgb; pastel color is rgb color with lower satuation (coeff expected in [0.0, 1.0])
    vec3 hsv = rgb2hsv(rgb);
    hsv.y *= saturationMultCoeff;
    return hsv2rgb(hsv);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //Resizing coordinates
    vec2 uv = fragCoord/iResolution.xy;
      
    uv -=0.5;
    uv *=2.;
    
    uv.x *= iResolution.x/iResolution.y;  
    
    ///////////////////////////
    //Input parameters
    
    ////Ray marching  
    vec3 ro = vec3(0., 0., 1.);  //origin point for rays
    //vec3 rd = normalize(rotate3D(vec3(uv, -1.) -ro, vec3(0., 1., 0.), 2.*pi/30.*cos(iTime*2.*pi/24.))+ro); //rays directions on projection screen
    vec3 rd = normalize(rotate3D(vec3(uv, -1.) -ro, vec3(0., 1., 0.), 2.*pi/30.*cos(iTime*2.*pi/24.))); //alternative change for view change (uncomplete projection on the screen)
    float d,t = 0.; // travelled distance
    vec3 p = ro + rd * t;//initialization of current position of points on rays
    Element res_scene = Element(1., vec3(1.));//initialization of the scene with colors
    
    int nbIter = 200; //number of iterations
    float d_min = 0.01;
    float t_max = 100.;
    
    ////Lighting
    vec3 lightPos = vec3(0., 2., -1.);
    float lightDifIntensity = 5.;
    float lightDifGamma = 0.4545;
    
    ////Color initialization and background, light and shades colors
    vec3 col = vec3(0., 0., 0.); //color vector initialization
    //vec3 backgroundColor = vec3(0.2, 0.3, 0.7);
    //vec3 backgroundColor = vec3(0.1, 0.6, 0.7);
    vec3 backgroundColor = vec3(0.13, 0.78, 0.91);
    vec3 darkColor = vec3(0.259, 0.392, 0.510);
    vec3 lightColor = vec3(0.4);
    float pastelSaturationCoeff = 0.5;
    
    ///////////////////////////
    
    // Raymarching
       
    for (int i = 0; i<nbIter; i++){
    
        res_scene = scene(p);
        d = res_scene.sd; //signed distance to the scene
       
        t += d; //for next iteration   
        p =ro + rd * t; //current position updating
    
    
        if (d < d_min || t > t_max){break;}; 
    };
    


    //Colors and lighting
    
    if (d < d_min){
        
        vec3 normal = calcNormal(p); //normals for light diffusion
        
        float intensity = lightDifIntensity * clamp(dot(normal, normalize(lightPos - p)), 0., 1.); //light intensity is the dot product of the light ray to the point of the scene and the normal of this point (multiplied here by a constant)
        //float dif = intensity / dot(lightPos - p, lightPos - p); //light diffusion: light intensity correction divided by the radiance which is the square of the ray length since intensity is proportionnal to the square of the distance       
        //dif = pow(dif, lightDifGamma);     //light gamma correction
           
        //float mainShading = step(0.15*lightDifIntensity, intensity);
        float mainShading = smoothstep(0.1*lightDifIntensity, 0.2*lightDifIntensity, intensity);
        float borderShading = 1. - mainShading;
        float topShading = step(0.99*lightDifIntensity, intensity);
        //float topShading = smoothstep(0.99*lightDifIntensity, 1.0*lightDifIntensity, intensity);
              
            
        col = mainShading * make_rgb_pastel(res_scene.col, pastelSaturationCoeff) + borderShading * make_rgb_pastel(darkColor, pastelSaturationCoeff) + topShading * make_rgb_pastel(lightColor, pastelSaturationCoeff);        
        
        
        //col = vec3(t*0.1);
        
    } else { //no ray intersection : default color
           
        col = make_rgb_pastel(backgroundColor, pastelSaturationCoeff);
    };


    //Output screen display
    fragColor = vec4(col,1.0);
}