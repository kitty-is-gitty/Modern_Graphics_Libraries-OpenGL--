// Created by Robert Schuetze - trirop/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Compute divergence
#iChannel0 "buf://C:\Users\sutir\OneDrive\Desktop\Progs\projects\Fractals\opengl\multistep_fluid\BufferA.glsl"
void mainImage( out vec4 fragColor, in vec2 C )
{
    vec2 r = iResolution.xy;
    float vxl = texture(iChannel0,(C-vec2(-1, 0))/r).x;
    float vxr = texture(iChannel0,(C-vec2( 1, 0))/r).x;
    float vyt = texture(iChannel0,(C-vec2( 0,-1))/r).y;
    float vyb = texture(iChannel0,(C-vec2( 0, 1))/r).y;
    float div = (vxl-vxr+vyt-vyb)/2.;
    fragColor = vec4(div,0,0,1);
}