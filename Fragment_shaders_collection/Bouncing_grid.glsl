#define PI 3.14158

vec2 matRot2D(vec2 vect, float angleRad, vec2 centerRot){
    vec2 vectOffset = vect - centerRot;
    return vec2(vectOffset.x*cos(angleRad)+vectOffset.y*sin(angleRad), -1.*vectOffset.x*sin(angleRad)+vectOffset.y*cos(angleRad)) + centerRot;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from -0.5 to 0.5 with x and y same scale)
    //vec2 uv = fragCoord/iResolution.xy;
    //uv -= 0.5;
    //uv.x*=iResolution.x/iResolution.y;
    
    vec2 uv = (fragCoord.xy - 0.5*iResolution.xy)/iResolution.y; //simplified form

    // Time varying pixel color
    
    //float val = 5.; //half of number of squares on y axis
    //float val = 10.*(1.5+cos(iTime));
    float val = 6.;
    
    //vec2 centerRot = floor(uv*2.*val);
    //vec2 centerRot = floor(uv*2.*val)/2./val + 0.5 * sign(uv);
    //vec2 centerRot = (floor(uv*2.*val)+ 0.5 * sign(uv))/2./val;
    vec2 centerRot = (floor(uv*2.*val)+ 0.5)/2./val;
    //vec2 centerRot = (floor(uv*2.*val*(1.+vec2(pow(cos(iTime),2.), pow(sin(iTime),2.))))+ 0.5)/2./val;
    //vec2 centerRot = vec2(0.);
    
    //float freqRot = length(centerRot)*1.; //s^(-1)
    float freqRot = 0.125;
    
    //float phasis = 0.;
    //float phasis = length(uv)/1.*2.*PI;
    float phasis = length(centerRot)*0.1/1.*2.*PI;
    //float phasis = (centerRot.y-centerRot.x)/1.*2.*PI;
    
    //vec3 col1 = vec3(0.2, 0.4, 1.);
    vec3 col1 = vec3(0.2, 0.4, 1.)+vec3(mod(length(centerRot),0.15));
    
    //vec3 col2 = vec3(0.6, 0.4, -0.8);
    vec3 col2 = vec3(0.2, 0.2, 0.1);
    //vec3 col2 = vec3(0.);
    
    //vec3 col3 = vec3(0.1); //color of progressive lighting
    //vec3 col3 = vec3(0.05);
    //vec3 col3 = vec3(0.3)*(1.1-length(uv));
    //vec3 col3 = vec3(-0.3)*(length(uv));
    //vec3 col3 = vec3(-0.3)*1.5*(exp(-0.5*length(uv)));
    vec3 col3 = vec3(-0.3)*1.4*(1.-exp(-2.5*length(uv)));
    
    //vec3 col = (0.6 + 0.4*mod(floor(val*uv.x) + floor(val*uv.y), 2.0)) * col1; //tiled grid
    //vec3 col = (0.6 + 0.4*mod(length(uv), 2.0)) * col1; //tiled grid
    //vec3 col = (0.6 + 0.4*mod(length(uv)+max(uv.x,uv.y)/length(uv), 2.0)) * col1; //tiled grid
    //vec3 col = (0.6 + 0.4*mod(floor(val*(1.+pow(cos(iTime),2.))*uv.x) + floor(val*(1.+pow(cos(iTime),2.))*uv.y), 2.0)) * col1; //tiled grid
    //vec3 col = (0.6 + 0.4*mod(floor(val*(1.+pow(cos(iTime),2.))*uv.x) + floor(val*(1.+pow(sin(iTime),2.))*uv.y), 2.0)) * col1; //tiled grid
    //vec3 col = (0.6 + 0.4*mod(floor(val*(1.+pow(cos(iTime),2.))*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).x) + floor(val*(1.+pow(cos(iTime),2.))*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).y), 2.0)) * col1; //tiled grid
    //vec3 col = (0.6 + 0.4*mod(floor(val*(1.+pow(cos(iTime),2.))*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).x) + floor(val*(1.+pow(sin(iTime),2.))*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).y), 2.0)) * col1; //tiled grid
    //vec3 col = (0.6 + 0.4*mod(floor(val*2.*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).x) + floor(val*2.*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).y), 2.0)) * col1; //tiled grid   
    //vec3 col = (0.6 + 0.4*mod(floor(val*2.*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).x) + floor(val*2.*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).y), 2.0)+0.25*pow(cos((iTime*2.*PI*freqRot-phasis)/2.),2.0)) * col1; //tiled grid    
    //vec3 col = (0.6 + 0.4*mod(floor(val*2.*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).x) + floor(val*2.*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).y), 2.0)) * col1 + (0.5*pow(cos((iTime*2.*PI*freqRot-phasis)/2.),2.0)) * col2; //tiled grid     
    vec3 col = (0.6 + 0.4*mod(floor(val*2.*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).x) + floor(val*2.*matRot2D(uv, PI/2.*cos(iTime*2.*PI*freqRot-phasis), centerRot).y), 2.0)) * col1 + (0.5*pow(cos((iTime*2.*PI*freqRot-phasis)/2.),2.0)) * col2 + pow(cos((iTime*2.*PI*freqRot-phasis+PI/2.)*1.),2.0) * col3; //tiled grid  
    
    // Output to screen
    fragColor = vec4(col,1.0);
}