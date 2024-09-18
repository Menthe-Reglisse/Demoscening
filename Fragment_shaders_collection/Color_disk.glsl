float pi = 3.14159;

vec3 col1 = vec3(0.5, 0.5, 0.5);
vec3 col2 = vec3(0.5, 0.5, 0.5);
vec3 col3 = vec3(2.0, 1.0, 0.0);
vec3 col4 = vec3(0.5, 0.2, 0.25);
	


// Palette function from Inigo Quilez: https://iquilezles.org/articles/palettes/
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 2.*pi*(c*t+d) );
}


float atan2( float y, float x) {

    float delta = 0.;

    if (x<0.) {
    
        if (y<0.) { 
        delta = -1.*pi;
        }else{ 
        delta = pi;
        }
        
   };
   
   return atan(y/x) + delta;   
   
   }

vec2 vectRot (vec2 vectIni, float rotAngle){

    mat2 matRot= mat2(cos(rotAngle), sin(rotAngle),-sin(rotAngle), cos(rotAngle));
    return matRot*vectIni;

}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //Coordinates mapping
    
    vec2 uv = fragCoord/iResolution.xy;   
    uv -= 0.5;   
    uv.x *= iResolution.x/iResolution.y;
    
    //uv = fract(uv*10.);
       
    uv = vectRot(uv, iTime);
    
    //uv = fract(uv*10.);

    float polar_distSquare = pow(uv.x, 2.) + pow(uv.y, 2.);
    float polar_angle=atan2(uv.y, uv.x);
    //float polar_angle_normalized = polar_angle/2./pi+0.5;
    float indicAngle = cos(polar_angle)*sin(polar_angle);
    vec2 polar = vec2 (polar_distSquare, indicAngle);  


    // Color
    
    //polar.x = fract(polar.x*10.);
    //polar.y = fract(polar.y*10.);
    
    polar.x = fract(polar.x*abs((mod(iTime+10.,20.)-10.)));
    polar.y = fract(polar.y*abs((mod(iTime+10.,20.)-10.)));    
    
    //vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
    
    //vec3 col = vec3(polar.x, polar.y, 1.);
    
    //vec3 colRes1 = pal(polar.x, col1, col2, col3, col4);
    //vec3 colRes2 = pal(polar.y, col1, col2, col3, col4);
    //vec3 col = max(colRes1, colRes2);    
    
    mat3 matCol = mat3(-0.8,-0.8,-0.8, //each row corresponds to a column
                       0.6,0.25,0.25,
                       0.3,0.7,0.7);
    vec3 col = clamp(matCol*vec3(polar.x, polar.y, 1.),0., 1.);
    
    //col.x=fract(col.x*10.);
    //col.y=fract(col.y*10.);
    


    // Output screen display
    
    fragColor = vec4(col, 1.0);
    
}