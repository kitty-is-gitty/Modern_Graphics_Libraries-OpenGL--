// solve for pressure


//macro

#define GetState(I,J) texelFetch( iChannel0, ijCoord+ivec2(I,J), 0 ).w
#define GetVelocity(I,J) texelFetch( iChannel1, ijCoord+ivec2(I,J), 0 ).xy
#define GetPressure(I,J) texelFetch( iChannel3, ijCoord+ivec2(I,J), 0 ).w

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    //set grid
    float dx = 1.0 / iResolution.y;
    float dxPow = dx *dx ;
    
    vec2 uvCoord = dx*fragCoord.xy;
    ivec2 ijCoord = ivec2(floor(fragCoord.xy));
    
    // no-flow inside obstacle
    float stateij = GetState(0,0);
    float stateip1j = GetState(1,0);
    float stateim1j = GetState(-1,0);
    float stateijp1 = GetState(0,1);
    float stateijm1 = GetState(0,-1);    

    if (stateij == 1.0) 
    {
        fragColor = vec4(0,0,0,0);
        return;
    }
    
    //to compute velocity finite difference approximaton
    vec2 vitauxij = GetVelocity(0,0); 
    vec2 vitauxip1j = mix(GetVelocity(1,0),-vitauxij, stateip1j);
    vec2 vitauxim1j = mix(GetVelocity(-1,0),-vitauxij, stateim1j);
    vec2 vitauxijp1 = mix(GetVelocity(0,1),-vitauxij, stateijp1);
    vec2 vitauxijm1 = mix(GetVelocity(0,-1),-vitauxij, stateijm1);
    
    //to compute pressure finite difference approximaton
    float presij = GetPressure(0,0); 
    float presip1j = mix(GetPressure(1,0),presij,stateip1j);
    float presim1j = mix(GetPressure(-1,0),presij,stateim1j);
    float presijp1 = mix(GetPressure(0,1),presij,stateijp1);
    float presijm1 = mix(GetPressure(0,-1),presij,stateijm1);
    
    
    // set outer boundary conditions
    if(ijCoord.x ==  int(iResolution.x)-1)
    {
        vitauxip1j = vitauxij;
        presip1j = presij;
    }
    if(ijCoord.x == 0)
    {
        vitauxim1j =  2.0*vec2(flowSpeed*uvCoord.y*(1.0-uvCoord.y),0.0)-vitauxij;
        presim1j = -presij;
    }
    if(ijCoord.y ==  int(iResolution.y)-1)
    {
        vitauxijp1 = -vitauxij;
        presijp1 = presij;
    }
    
    if(ijCoord.y == 0)
    {
        vitauxijm1 =  -vitauxij;
        presijm1 = presij;
    }
    
    
    // compute velocity divergence
    float div = 0.5*(vitauxip1j.x-vitauxim1j.x+vitauxijp1.y-vitauxijm1.y)/dx;
    float vort = 0.5*(vitauxijp1.y-vitauxim1j.y + vitauxijp1.x-vitauxijm1.x)/dx;
    // should use more than 1 iteration...
    // compute pressure (auxiliary) via jacobi iteration... 
    float presDiff = 0.25*((presip1j+presim1j)+(presijp1+presijm1)-dxPow*reynold*div/dt);
        
    fragColor = vec4(presDiff, div, vort,0);
}
