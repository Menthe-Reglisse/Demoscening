#define PI 3.14159

float hash11(float st){
    return fract(sin(dot(vec2(st,34.431),
                         vec2(614.,48.12)))*
        193245.234);
}

float hash21(vec2 st) {
    float timeWait = 1.; //in s
    float nbReset = 5.; //nb before pattern loop reset
    return fract(sin(dot(st.xy,
                         vec2(614.*(hash11(mod(floor(iTime/timeWait),nbReset))),48.12)))*
        193245.234);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.y;
    vec2 uvIni = uv;
   
    
    //float nb = 11.+10.*cos(iTime);
    float nb=15.;

    uv = fract(uv*nb+0.5)-0.5;


    //vec3 col = hash21(floor((uvIni-0.5/nb)*nb))*vec3(0.1,0.4,0.8);
    vec3 col = hash21(floor((uvIni-0.5/nb)*nb))*vec3(0.1,uv.y+0.5,uv.x+0.5);
    
    
    //if((abs(uv.x)>0.49) || (abs(uv.y)>0.49))col = vec3(0., 0., 1.);
    

    fragColor = vec4(col,1.0);
    
    
    
}