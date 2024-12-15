// project for incompressibility



//macro
#define GetState(I,J) texelFetch( iChannel0, ijCoord+ivec2(I,J), 0 ).w
#define GetVelocity(I,J) texelFetch( iChannel1, ijCoord+ivec2(I,J), 0 ).xy
#define GetDensity(I,J) texelFetch( iChannel1, ijCoord+ivec2(I,J), 0 ).z

#define GetPressure(I,J) texelFetch( iChannel2, ijCoord+ivec2(I,J), 0 ).x
#define GetDivergence(I,J) texelFetch( iChannel2, ijCoord+ivec2(I,J), 0 ).y

float pres(float coef, ivec2 ijCoord,int i, int j){
    
    
    float stateip1j = GetState(i+1,j);
    float stateim1j = GetState(i-1,j);
    float stateijp1 = GetState(i,j+1);
    float stateijm1 = GetState(i,j-1);    
    
    
    float div = GetDivergence(i,j); 
    float presij = GetPressure(i,j); 
    
    
    float presip1j = mix(GetPressure(i+1,j),presij,stateip1j);
    float presim1j = mix(GetPressure(i-1,j),presij,stateim1j);
    float presijp1 = mix(GetPressure(i,j+1),presij,stateijp1);
    float presijm1 = mix(GetPressure(i,j-1),presij,stateijm1);
    
// set outer boundary conditions
    if(ijCoord.x >=  int(iResolution.x)-1)
    {
        presip1j = presij;
    }
    if(ijCoord.x <= 0)
    {
        presim1j = -presij;
    }
    if(ijCoord.y >=  int(iResolution.y)-1)
    {
        presijp1 = presij;
    }
    
    if(ijCoord.y <= 0)
    {
        presijm1 = presij;
    }
    
    return 0.25*((presip1j+presim1j)+(presijp1+presijm1)-coef*div);
}


float pres2(float coef, ivec2 ijCoord,int i, int j){
    float div = GetDivergence(i,j); 
    float presij = pres(coef, ijCoord, i,j);
    float presip1j = pres(coef, ijCoord, i+1,j);
    float presim1j = pres(coef, ijCoord, i-1,j);
    float presijp1 = pres(coef, ijCoord, i,j+1);
    float presijm1 = pres(coef, ijCoord, i,j-1);
    


    return 0.25*((presip1j+presim1j)+(presijp1+presijm1)-coef*div);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    //set grid
    float dx = 1.0 / iResolution.y;
    float dxPow = dx *dx ;
    float coef = dxPow*reynold/dt;
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
    
    //to compute diveergence finite difference approximaton
    //to compute velocity finite difference approximaton
    vec2 vitauxij = GetVelocity(0,0); 
    
    
    float presij = pres2(coef, ijCoord, 0,0);
    float presip1j = pres(coef, ijCoord, 1,0);
    float presim1j = pres(coef, ijCoord, -1,0);
    float presijp1 = pres(coef, ijCoord, 0,1);
    float presijm1 = pres(coef, ijCoord, 0,-1);
    
    
    
    //compute gradiant of pressure
    vec2 presGrad = 0.5*vec2(presip1j-presim1j, presijp1-presijm1)/dx;
    
    //projection (helmholtz-hodge) to obtain divergence free
    vec2 vit;
    
    if (ijCoord.x < 10 ) {
        vit = vec2(flowSpeed*uvCoord.y*(1.0-uvCoord.y),0.0);
    }
    else
    {
        vit = vitauxij-dt/reynold*presGrad;
    }
    float dens = GetDensity(0,0);
    
    
    
    
    
    fragColor = vec4(vit, dens, presij);
}