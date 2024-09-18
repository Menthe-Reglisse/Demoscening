// Inspired from Inigo Quilez star signed distance function: https://www.shadertoy.com/view/WtdBRS
// Inspired from Inigo Quilez handlings of distance functions (boolean operations (smooth, not smooth) and extrusion) : http://iquilezles.org/articles/
// Inspired from Kishimisu tutorial: https://www.youtube.com/watch?v=khblXafu7iA
// Added additionnal forms features from Unigo Quilez website: https://iquilezles.org/articles/distfunctions/
// Shades lighting (normals and diffusion) and distorsion removal inspired from Reinder: https://www.shadertoy.com/view/4dSBz3 (tutorial: https://www.shadertoy.com/view/4dSfRc)
// Coloring inspired from Inspirnathan: https://www.shadertoy.com/view/fdjGRD (https://inspirnathan.com/posts/54-shadertoy-tutorial-part-8/)

float pi = 3.14159;
vec3 col1 = vec3(81.,40.,66.)/255.; //red from the coat of arms
vec3 col2 = vec3(230.,230.,230.)/255.;//gray from the coat of arms
#define col3 (col1+col2)/2.;

float max3(vec3 p){ // maximum element of a 3D vector
    return max(max(p.x, p.y), p.z);
}

vec2 rotate2D(vec2 vectIni, float rotAngle){

    mat2 matRot= mat2(cos(rotAngle), sin(rotAngle),-sin(rotAngle), cos(rotAngle));
    return matRot*vectIni;

}

struct Element {
    float sd; //signed distance
    vec3 col; //color
};

float op_round( float d, float l){
  return d - l;
}

float op_onion( float d, float l){
  return abs(d) - l;
}

float op_extrusion( vec3 p, float d_2D, float h){
    vec2 w = vec2( d_2D, abs(p.z) - h );
    return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}


float op_smoothUnion( float d1, float d2, float k ){
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

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

float sd_circle2D(vec2 p , float r){
    return length(p)-r;
}

float sd_star2D(vec2 p, float r, float n, float m){
    
    // next 4 lines can be precomputed for a given shape
    float an = 3.141593/float(n);
    float en = 3.141593/m;  // m is between 2 and n
    vec2  acs = vec2(cos(an),sin(an));
    vec2  ecs = vec2(cos(en),sin(en)); // ecs=vec2(0,1) for regular polygon

    float bn = mod(atan(p.x,p.y),2.0*an) - an;
    p = length(p)*vec2(cos(bn),abs(sin(bn)));
    p -= r*acs;
    p += ecs*clamp( -dot(p,ecs), 0.0, r*acs.y/ecs.y);
    return length(p)*sign(p.x);
              
              
}



float sd_star3D(vec3 p, float r, float n, float m, float h){

    float d_2D=sd_star2D(p.xy, r, n, m);
    return op_extrusion(p, d_2D, h);
                 
}

float sd_sombreLune2D(vec2 p, float ra, float n, float m, float r){

    float d1=sd_star2D(p, ra, n, m);
    float d2=sd_circle2D(p , r);
    return max(-d1, d2);

}

float sd_sombreLune3D(vec3 p, float ra, float n, float m, float r, float h){
    float d_2D=sd_sombreLune2D(p.xy, ra, n, m, r);
    return op_extrusion(p, d_2D, h);

}

float sd_ring2D(vec2 p, float r, float l){

    float d = sd_circle2D(p , r);
    return op_onion(d, l);

}

float sd_ring3D(vec3 p, float r, float l, float h){

    float d_2D = sd_ring2D(p.xy , r, l);
    return op_extrusion(p, d_2D, h);

}

Element unionSmoothElement (Element elem_1, Element elem_2, float k, float col_trigger){ //k in [0.0, 1.0]; col_trigger in [0.0, 1.0]

  //return Element(op_smoothUnion(elem_1.sd, elem_2.sd, k), elem_1.sd>elem_2.sd?elem_2.col:elem_1.col); //no color smooth transition (correspond to the smooth color transition with col_triger =0.0)
  
  vec3 col = mix(elem_1.col, elem_2.col, smoothstep(-col_trigger,col_trigger,elem_1.sd-elem_2.sd)); //smooth color transition
  return Element(op_smoothUnion(elem_1.sd, elem_2.sd, k), col);
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

            
    vec3 sombreLunePos = vec3 (0., 0.5, -3.);
    vec3 sombreLuneRotAxis = vec3 (1., 1., 1.);
    float sombreLuneRotAngle = iTime*2.*pi*0.1;
    float sombreLune_ra = 1.0;
    float sombreLune_n = 6.;
    float sombreLune_m = 4.;
    float sombreLune_r = 1.5;
    float sombreLune_h = 0.2; 
    float sombreLune_sd = sd_sombreLune3D(rotate3D(p - sombreLunePos, sombreLuneRotAxis, sombreLuneRotAngle), sombreLune_ra, sombreLune_n, sombreLune_m, sombreLune_r, sombreLune_h);
    vec3 sombreLune_col = col1*0.4;
    Element sombreLune = Element(sombreLune_sd, sombreLune_col);
    //res=minElement(res, sombreLune); 
           
    vec3 ringPos = vec3 (0., 0.5, -3.);
    vec3 ringRotAxis = vec3 (-1.3, 0.2, 1.);
    float ringRotAngle = iTime*2.*pi*0.05;
    float ring_r = sombreLune_r*1.15;
    float ring_l = ((ring_r/sombreLune_r - 1.)*sombreLune_r)*0.2;
    float ring_h = sombreLune_h; 
    float ring_sd = sd_ring3D(rotate3D(p - ringPos, ringRotAxis, ringRotAngle), ring_r, ring_l, ring_h);
    vec3 ring_col = col2*0.4;
    Element ring = Element(ring_sd, ring_col);
    res=minElement(res, ring);    
        
    
    vec3 starPos = vec3 (0., 0.5, -3.);
    vec3 starRotAxis = vec3 (1., 1., 1.);
    float starRotAngle = iTime*2.*pi*0.1;
    float star_ra = 1.0;
    float star_n = 6.;
    float star_m = 4.;
    float star_h = 0.2;
    vec3 p_starRotate3D = rotate3D(p - starPos, starRotAxis, starRotAngle);
    float starOffsetAmplitude = star_h*2.*2.5;
    vec3 p_starOffset=normalize(starPos)*starOffsetAmplitude*cos(pi/2.+iTime*2.*pi*0.05);
    float star_sd = sd_star3D(p_starRotate3D+p_starOffset, sombreLune_ra , sombreLune_n, star_m, star_h);
    vec3 star_col = col2*0.4;
    Element star = Element(star_sd, star_col);
    //res=minElement(res, star);
    
    
    float sombreLune_and_star_distanceRatio = clamp(length(p_starOffset)/starOffsetAmplitude,0., 1.);
    float sombreLune_and_star_k = 0.85*sombreLune_and_star_distanceRatio;
    float sombreLune_and_star_colTrigger = 1.0*sombreLune_and_star_distanceRatio;
    Element sombreLune_and_star = unionSmoothElement(sombreLune, star, sombreLune_and_star_k, sombreLune_and_star_colTrigger);       
    res=minElement(res, sombreLune_and_star);
    
       
    float groundPos = -3.;
    float ground_sd = p.y - groundPos;
    vec3 ground_col = (0.6 + 0.4*mod(floor(p.x) + floor(p.z), 2.0)) * col3; //tiled grid
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
    vec3 ro = vec3(0., 0.5, 0.25);  //origin point for rays
    vec3 rd = normalize(rotate3D(vec3(uv, -1.) -ro, vec3(0., 1., 0.), 2.*pi/120.*cos(pi/2.+iTime*2.*pi*0.05))+ro); //rays directions on projection screen    
    float d,t = 0.; // travelled distance
    vec3 p = ro + rd * t;//initialization of current position of points on rays
    Element res_scene = Element(1., vec3(1.));//initialization of the scene with colors
    
    int nbIter = 200; //number of iterations
    float d_min = 0.01;
    float t_max = 100.;
    
    ////Lighting
    vec3 lightPos = vec3(0., 0.5, -1.);
    float lightDifIntensity = 120.+30.*cos(pi/2.+iTime*2.*pi*0.1);
    //float lightDifGamma = 0.4545;
    float lightDifGamma = 0.25;
    
    ////Color initialization and background color
    vec3 col = vec3(0., 0., 0.); //color vector initialization
    //vec3 backgroundColor = vec3(0.2, 0.3, 0.7);
    //vec3 backgroundColor = vec3(0.1, 0.05, 0.7)*(0.5 +0.25*cos(-pi/2.+iTime*2.*pi*0.1)); 
    vec3 backgroundColor = vec3(0.05, 0.2, 0.7)*(0.5 +0.25*cos(-pi/2.+iTime*2.*pi*0.1));    
    
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
        float dif = intensity / dot(lightPos - p, lightPos - p); //light diffusion: light intensity correction divided by the radiance which is the square of the ray length since intensity is proportionnal to the square of the distance       
        dif = pow(dif, lightDifGamma);     //light gamma correction
        
        col = res_scene.col * dif;
        //col = vec3(t*0.1);
        
    } else { //no ray intersection : default color
           
        col = backgroundColor;
    };


    //Output screen display
    fragColor = vec4(col,1.0);
    
}