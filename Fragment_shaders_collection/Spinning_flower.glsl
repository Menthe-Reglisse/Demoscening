// Inspired from nimitz: https://www.shadertoy.com/view/XdSSRw for optimization function
// Search minimum from proposition of harry7557558 in the comments of nimitz's shader
// Vignette effect from Inigo Quilez (profile page: https://www.shadertoy.com/user/iq)
// Parametric equation for 2D flowers from Sambrunacini: http://sambrunacini.com/parametric-flowers/

#define time iTime
#define pi 3.14159265
#define duration 50. //animation duration in s

//Three types of color depending on the value of the variable "colorTypeVary" in the code (==1. -> Ocean; ==2. -> Vintage; ==3. -> Argon)
#define colorDuration (50./2./4.) //duration in s between color change (halfAnimationDuration/(nbTypesOfIntegerPetals-1.))

//Two types of petals: 1 for long-rounded petals; 2 for long-flat petals
#define petalType 1

//might need to be adjusted depending on the curve
#define STRIDE 0.035


//2D rotation
vec2 rot2D(vec2 vect, float angle){
    return vec2(vect.x*cos(angle)+vect.y*sin(angle),-vect.x*sin(angle)+vect.y*cos(angle));
}

//Flower parametric equation
vec2 f(in float t)
{   
    //float b = 6.+2.*cos(iTime*2.*pi/duration); //sine wave for petal number variation for a variation speed effect, but color changes do not necessary occur when b is an integer (b integer implies the flower is a simple closed loop function with no overlapping petals)
    float b = 6.+2.*(2.*(2.*abs(iTime/duration-0.5-floor(iTime/duration))-0.5)); //triangle wave function: color changes occur when the number of petals is an integer, but the petal number variation is continuous at constant speed (triangle wave equation: https://en.wikipedia.org/wiki/Triangle_wave)

    #if petalType == 1
    float func_flower = abs(2./pi*(mod(b*t-pi/2.,2.*pi)-pi))-1.; //flower from the first example of Sambrunacini
    //float func_flower = 2.*asin(sin(b*t))/pi; //alternative
    #elif petalType == 2
    float func_flower = sqrt(abs(2.*(2.*abs(b*t/2./pi+0.25-floor(b*t/2./pi+0.75))-0.5)))*(2.*mod(ceil(b*t/pi),2.)-1.);  //flower with custom petals created for this shader
    #endif
   
    float x = (2.+func_flower)*cos(t);
    float y = (2.+func_flower)*sin(t);
    
    
    //float angleNotSmooth = (1.-mod(b,2.))*pi/2./b; // no orientation of flower needed to be straight if odd number of petals; otherwise, rotation of an angle equal to pi/2./nbPetals (works also for any number of petals with decimal part equal to 0.5)
    float angleSmooth = (pi/2./b/2.)*(1.+cos(2.*pi*b/2.)); //sine wave of varying amplitude with an offset equal to the amplitude (the amplitude is the angle continuous rotation: pi/2./b)
   
    return 2.*rot2D(vec2(x,y),angleSmooth); 
}

//Squared distance from point (pixel) to curve
float fd(in vec2 p, in float t)
{
    p = p+f(t);
    return dot(p,p);
}

//Golden ratio search for bissection
float bisect(in vec2 p, in float near, in float far)
{
	const float g1 = 0.618034, g0 = 1.0 - g1;
    float x0 = near, x1 = far;  // boundary points
	float t0 = g1 * x0 + g0 * x1;  // middle point 1
	float t1 = g0 * x0 + g1 * x1;  // middle point 2
	float y0 = fd(p, t0), y1 = fd(p, t1);  // middle samples
	for (int i = 0; i <= 7; i++)
    {
		if (y0 < y1) {
			x1 = t1, y1 = y0;
			t1 = t0, t0 = g1*x0+g0*x1;
			y0 = fd(p, t0);
		}
		else {
			x0 = t0, y0 = y1;
			t0 = t1, t1 = g0*x0+g1*x1;
			y1 = fd(p, t1);
		}
		if (abs(y1-y0) < 0.001) break;
	}
    return length(p+ f(y0 < y1 ? t0 : t1));
}

//Optimization function for intersection
float intersect(in vec2 p, in float near, in float far)
{
    float t = near;
    float told = near;
    float nr = 0., fr = 1.;
    float mn = 10000.;
    
    for (int i = 0; i <= 300; i++)
    {
        float d = fd(p, t);
        if (d < mn)
        {
            mn = d;
            nr = told;
            fr = t+.05;
        }
        if (t > far)break;
        told = t;
        t += log(d+1.15)*STRIDE;
    }
    
   	return bisect(p, nr,fr);
}

//Reinhard based tone mapping
vec3 tone(vec3 color, float gamma)
{
	float white = 2.;
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma * (1. + luma / (white*white)) / (1. + luma);
	color *= toneMappedLuma / luma;
	color = pow(color, vec3(1. / gamma));
	return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = fragCoord.xy / iResolution.xy-0.5;
    vec2 bp = p+0.5;
	p.x *= iResolution.x/iResolution.y;
    p *= 19.;
    float rz = intersect(p,0.,30.);
    vec3 col = vec3(0.);
    
    float colorTypeVary = mod(floor(iTime/colorDuration),3.)+1.;
  
    if (colorTypeVary==1.){
    
    rz = pow(rz*10.,0.11);
    col = vec3(0.2,1.5,2.)*1.-log(rz+0.8);
    col = clamp(col,0.2,1.);
    col = mix(col,tone(col,2.),0.2);
    }
    else if (colorTypeVary == 2.){
    col = vec3(5.,1.5,.5)*log(rz+1.05);
    col = tone(col,8.5);
    }
    else
    {
    rz = pow(rz*20.,.85);
    col = vec3(.6,.2,1.)/(rz+1.5)*9.;
    col = tone(col,1.4);  
    }
    
    //Vignette effect
	col *= pow(16.0*bp.x*bp.y*(1.0-bp.x)*(1.0-bp.y),0.45);
    
	fragColor = vec4(col,1.0);
}