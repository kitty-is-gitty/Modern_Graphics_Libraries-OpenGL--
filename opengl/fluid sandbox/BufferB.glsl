// solve for diffusion



//macro
#define GetVelocity(I,J) texelFetch( iChannel0, ijCoord+ivec2(I,J), 0 ).xy
#define GetDensity(I,J) texelFetch( iChannel0, ijCoord+ivec2(I,J), 0 ).z
#define GetState(I,J) texelFetch( iChannel0, ijCoord+ivec2(I,J), 0 ).w




void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    // set grid
    float dx = 1.0 / iResolution.y;
    float dxPow = dx *dx ;
    vec2 uvCoord = dx*fragCoord.xy;
    ivec2 ijCoord = ivec2(floor(fragCoord.xy));
    
    //set die parameters
    float bandWidth = 1.0/float(bandDens*bandNb);
    float gapWidth = (1.0-float(bandNb)*bandWidth)/float(bandNb+1);
    
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
    vec2 vitij = GetVelocity(0,0); 
    vec2 vitip1j = mix(GetVelocity(1,0),-vitij, stateip1j);
    vec2 vitim1j = mix(GetVelocity(-1,0),-vitij, stateim1j);
    vec2 vitijp1 = mix(GetVelocity(0,1),-vitij, stateijp1);
    vec2 vitijm1 = mix(GetVelocity(0,-1),-vitij, stateijm1);
    
    
    //to compute density finite difference approximaton
    float densij = GetDensity(0,0); 
    float densip1j = mix(GetDensity(1,0),-densij, stateip1j);
    float densim1j = mix(GetDensity(-1,0),-densij, stateim1j);
    float densijp1 = mix(GetDensity(0,1),-densij, stateijp1);
    float densijm1 = mix(GetDensity(0,-1),-densij, stateijm1);
    
    // set outer boundary conditions
    if(ijCoord.x ==  int(iResolution.x)-1)
    {
        vitip1j = vitij;
        densip1j = densij;
    }
    
    if(ijCoord.x == 0)
    {
        vitim1j = 2.0*vec2(flowSpeed*uvCoord.y*(1.0-uvCoord.y),0.0)-vitij;
        densim1j =-densij;
    }
    if(ijCoord.y ==  int(iResolution.y)-1)
    {
        vitijp1 = -vitij;
        densijp1 = -densij;
    }
    
    if(ijCoord.y == 0)
    {
        vitijm1 = -vitij; 
        densijm1 = -densij; 
    }
    
   
    //should use more than 1 iteration...
    //solve with jacobi for new velocity with laplacian
    float coef = dt/(dxPow*reynold);
    vec2 vitaux = (vitij+coef*(vitip1j+vitim1j+vitijp1+vitijm1))/(1.0+4.0*coef);
 
    //should use more than 1 iteration...
    //solve with jacobi for new velocity with laplacian
    coef = kappa*dt/(dxPow);
    float densDiff = (densij+coef*(densip1j+densim1j+densijp1+densijm1))/(1.0+4.0*coef);
 
    
    fragColor = vec4(vitaux,densDiff,0.);
}