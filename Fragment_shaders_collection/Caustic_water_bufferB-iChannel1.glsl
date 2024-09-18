//Modification of my shader "Shining Truchet - v2": https://www.shadertoy.com/view/MfXSWf
//Inspired from The Art of Code: https://www.youtube.com/watch?v=2R7h76GoIJM and https://www.shadertoy.com/view/3lBXWK

float pi = 3.14159;

float random21 (vec2 uv) {

    vec2 calc = fract(uv * vec2(134.471, 242.878));
    
    calc += dot(calc, calc + 13.452);
    return fract(calc.x * calc.y);
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord.xy-0.5*iResolution.xy)/iResolution.y;
    
    uv += iTime*0.2;
    
    vec2 st = uv;
    
    float nb = 8.;
    uv = fract(uv*nb)-0.5;
    
    //st=fract(st);
    st=floor(st*nb);

    
    //float t = 0.1;
    float timeMove1 = abs(cos(iTime*2.*pi/4.));
    float timeMove2 = 0.5 + 0.5 * cos(iTime*2.*pi/32.);
    float t = 0.1 + 0.2 * timeMove1;
    float offset=0.5;
    
    float id = random21(st);

    float n;
    
    //if (id>0.5){
    //    n=1.;
    //}else{
    //    n=-1.;
    //}    
    id>0.5? n=1.:n=-1.; // shorter version of the "if ... else" statement
    
    //float line = smoothstep(0.1,0.,abs(abs(uv.x+n*uv.y)-offset)-t); // larger transition between low and high trigger values
    float line = smoothstep(0.1,0.,abs(abs(uv.x+n*uv.y)-offset)-t); //alternative (lower absolute value function)
    
    vec3 colBackground = clamp(vec3(0.1, 0.3, 0.4)*2. + vec3(0.05), 0., 1.);   
    vec3 colLines = clamp(vec3(0.3, 0.2, 0.)*0.4 + vec3(0.3), 0., 1.);
    
    //vec3 col1 = colBackground * timeMove2 + colLines * (1. - timeMove2);
    vec3 col1 = colBackground;
    vec3 col2 = colLines * timeMove2 + (colBackground - vec3(0.1)) * (1. - timeMove2);
    
    //vec3 col = colBackground*(1.-line) + colLines*line;
    vec3 col = col1*(1.-line) + col2*line;
    
    //float tickness = 0.02;
    //if (abs(uv.x)>(0.5-tickness/2.) || abs(uv.y)>(0.5-tickness/2.)) col = vec3(0.,0.,1.);

    fragColor = vec4(col,1.0);
}