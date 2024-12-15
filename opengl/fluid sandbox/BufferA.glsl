//Set initial condition / reset / obstacle / advection / force



//macro
#define GetVelocity(I,J) texelFetch( iChannel3, ijCoord+ivec2(I,J), 0 ).xy
#define GetState(I,J) texelFetch( iChannel0, ijCoord+ivec2(I,J), 0 ).w
#define GetDensity(I,J) texelFetch( iChannel3, ijCoord+ivec2(I,J), 0 ).z
#define GetVorticity(I,J) texelFetch( iChannel2, ijCoord+ivec2(I,J), 0 ).z

#define GetVelocityUV(XY) texture( iChannel3, vec2(XY)).xy
#define GetDensityUV(XY) texture( iChannel3, vec2(XY)).z

float isKeyPressed(int key)
{
	return texelFetch( iChannel1, ivec2(key, 0), 0 ).x;
}

vec2 Euler(vec2 posUV){
    return dt*GetVelocityUV(posUV);
}

vec2 Runge(vec2 posUV){
    vec2 k1 = GetVelocityUV(posUV);
    vec2 k2 = GetVelocityUV(posUV-0.5*k1*dt);
    vec2 k3 = GetVelocityUV(posUV-0.5*k2*dt);
    vec2 k4 = GetVelocityUV(posUV-k3*dt);
    return dt/6.*(k1+2.0*k2+2.0*k3+k4);
}

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
    
    
    
    // initial condition
    if (iFrame==0) {
        float densityAdv = 0.;
        
        // set obstacle
        float pert = length((fragCoord.xy) / iResolution.y-  vec2(0.15,0.5));   
        if( pert < (1.5*radiusObs)) {
            fragColor = vec4(0,0,0,1);
            return;
        }
        
        for (int k = 1;k<=bandNb;k++)
        {
            if (uvCoord.y >= gapWidth*float(k)+bandWidth*float(k-1) && 
                uvCoord.y <=  gapWidth*float(k)+bandWidth*float(k))
            {
                densityAdv = clamp(source*4.0*uvCoord.y*(1.0-uvCoord.y),0.0,0.5);
                break;
            }
        }
        fragColor = vec4(flowSpeed*uvCoord.y*(1.0-uvCoord.y),0,densityAdv,0);
        return;
    }
    // set obstacle
    float pert = length((fragCoord.xy - iMouse.xy) / iResolution.y);   
    if(iMouse.z > 0.0 && pert < radiusObs) {
        fragColor = vec4(0,0,0,1);
        return;
    }
    
    // no-flow inside obstacle
    float stateij = GetState(0,0);
    if (stateij == 1.0) 
    {
        fragColor = vec4(0,0,0,1);
        return;
    }
    
    // restet fluid keep obstacles
    if ( isKeyPressed(KEY_SPACE)!=0.0 )
    {
        fragColor = vec4(flowSpeed*uvCoord.y*(1.0-uvCoord.y),0,0,stateij);
        return;
    }
    
    // advect via semi-lagrangian method
    
    vec2 posUV =fragCoord/iResolution.xy;
    #ifdef EULER
    vec2 posAdvUV = posUV-Euler(posUV);
    #endif
    #ifdef RUNGE
    vec2 posAdvUV = posUV-Runge(posUV);
    #endif
    
    vec2 vitAdv;
    if(posAdvUV.x <= 0.0)  vitAdv = vec2(flowSpeed*posAdvUV.y*(1.0-posAdvUV.y),0.0);
    else vitAdv = GetVelocityUV(posAdvUV);
        
    float densityAdv = GetDensityUV(posAdvUV)/(1.0+dt*alpha);

    
    // vorticity confinement
    //to compute density finite difference approximaton
    
    float vortij = GetVorticity(0,0); 
    float vortip1j = GetVorticity(1,0); 
    float vortim1j = GetVorticity(-1,0); 
    float vortijp1 = GetVorticity(0,1); 
    float vortijm1 = GetVorticity(0,-1);
    
    vec3 gradVort = vec3(vortip1j-vortim1j,vortijp1-vortijm1,0.0);
    vec3 psi = gradVort / (length(gradVort)  + 1e-8);
    vec2 fv = cross(psi,vec3(0.0,0.0,vortij)).xy;
    
    vitAdv += epsilon*dt*dx*fv;
	
    
    // add force and sources
    vitAdv += dt*force;
    
    if(ijCoord.x == 0)
    {
        for (int k = 1;k<=bandNb;k++)
        {
            if (uvCoord.y >= gapWidth*float(k)+bandWidth*float(k-1) && 
                uvCoord.y <=  gapWidth*float(k)+bandWidth*float(k))
            {
                densityAdv = clamp(densityAdv+dt*source*4.0*uvCoord.y*(1.0-uvCoord.y),0.0,1.0);
                break;
            }
        }
    }
    
    fragColor = vec4(vitAdv, densityAdv, 0); 
}