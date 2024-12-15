// Variation of a precedent project
// https://www.shadertoy.com/view/MllBzr





//macro
#ichannel0 "file://C:\Users\sutir\OneDrive\Desktop\Progs\projects\Fractals\opengl\fluid sandbox\BufferA.glsl"
#define GetState(I,J) texelFetch( iChannel0, ijCoord+ivec2(I,J), 0 ).w
#define GetDensity(I,J) texelFetch( iChannel3, ijCoord+ivec2(I,J), 0 ).z
#define GetVelocity(I,J) texelFetch( iChannel3, ijCoord+ivec2(I,J), 0 ).xy
#define GetPressure(I,J) texelFetch( iChannel3, ijCoord+ivec2(I,J), 0 ).w
#define GetDivergence(I,J) texelFetch( iChannel2, ijCoord+ivec2(I,J), 0 ).y
#define GetVorticity(I,J) texelFetch( iChannel2, ijCoord+ivec2(I,J), 0 ).z

float isKeyPressed(int key)
{
	return texelFetch( iChannel1, ivec2(key, 0), 0 ).x;
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

// COLORMAP
float segment(float edge0, float edge1, float x)
{
    return step(edge0,x) * (1.0-step(edge1,x));
}


vec3 hot(float t)
{
    return vec3(smoothstep(0.00,0.33,t),
                smoothstep(0.33,0.66,t),
                smoothstep(0.66,1.00,t));
}


vec3 ice(float t)
{
   return vec3(t, t, 1.0);
}

vec3 fire(float t)
{
    return mix( mix(vec3(1,1,1), vec3(1,1,0), t),
                mix(vec3(1,1,0), vec3(1,0,0), t*t), t);
}

vec3 ice_and_fire(float t)
{
    return segment(0.0,0.5,t) * ice(2.0*(t-0.0)) +
           segment(0.5,1.0,t) * fire(2.0*(t-0.5));
}


// for testing purpose, https://www.shadertoy.com/view/4dlczB
vec3 blackbody(float t)
{
	float Temp = t*7500.0;
    vec3 col = vec3(255.);
    col.x = 56100000. * pow(Temp,(-3. / 2.)) + 148.;
   	col.y = 100.04 * log(Temp) - 623.6;
   	if (Temp > 6500.) col.y = 35200000. * pow(Temp,(-3. / 2.)) + 184.;
   	col.z = 194.18 * log(Temp) - 1448.6;
   	col = clamp(col, 0., 255.)/255.;
    if (Temp < 1000.) col *= Temp/1000.;
   	return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //set grid
    float dx = 1.0 / iResolution.y;
    float dxPow = dx *dx ;
    vec2 uvCoord = dx*fragCoord.xy;
    ivec2 ijCoord = ivec2(floor(fragCoord.xy));

    // no-flow inside obstacle
    float stateij = GetState(0,0);   
    
    if (stateij == 1.0) 
    {
        fragColor = vec4(0.5);
        return;
    }
    
    
	/// show field
    vec2 vit = GetVelocity(0,0); 
    float pres = GetPressure(0,0); 
    float dens = GetDensity(0,0); 
    float div = GetDivergence(0,0);
    float vort = GetVorticity(0,0);
    

    if ( isKeyPressed(KEY_ONE)!=0.0 )
    {
        fragColor =vec4(hot(0.25*(length(vit)+1.0)),1);
        //fragColor =vec4(1.0-hot(0.5*(length(vit)+1.0)),1);
        return;
    }
    if ( isKeyPressed(KEY_TWO)!=0.0 )
    {
        fragColor =vec4(1.0-hot(0.0005*(pres+800.0)),1);
        
        return;
    }
    if ( isKeyPressed(KEY_THREE)!=0.0 )
    {
        fragColor =vec4(1.0-hot(0.1*(div+5.0)),1);
        
        return;
    }
    if ( isKeyPressed(KEY_FOUR)!=0.0 )
    {
        fragColor =vec4(1.0-hot(0.1*(vort+5.0)),1);
        return;
    }

    //fragColor = vec4(ice_and_fire(clamp(dens,0.01,0.99)),1);
    //fragColor = vec4(1.0-blackbody(1.0-dens),1);
    fragColor = vec4(blackbody(dens),1);
  
    
}
