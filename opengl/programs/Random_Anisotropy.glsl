// Extended family of Voronoi
// Inspired by an idea by Hamoudi Moneimne
// Basically at each cell, evaluate different SDFs instead of point SDF
// Can introduce anisotropy by stretching these SDFs

// Change this to have non uniform anisotropy angle per cell
#define RANDOM_ANISOTROPY 0.1

struct CellData
{
    vec2 p1;
    vec2 p2;
};

CellData Sample(vec2 cellPosition, vec2 offset, vec2 anisoOffset)
{
	CellData cell;
    cell.p1 = hash22(cellPosition + offset) + anisoOffset + offset;
    cell.p2 = hash22((cellPosition + offset) * 54.53343) - anisoOffset + offset;
    return cell;
}

float SDF(vec2 p, CellData cell, float fx)
{
    float t = iTime * .2;
    int type = int(t);
    float fT = fract(t);
    
    float d[11];
    d[0] = min(Length(p - cell.p1), Length(p - cell.p2));
    
    // Segment
    d[1] = sdSegment(p, cell.p1, cell.p2);
    
    // Box 1
    d[2] =  sdBox(p - cell.p1, abs(cell.p1 - cell.p2));
    
    // Box intersection
    d[3] = max(-sdBox(p - cell.p1, cell.p2), sdBox(p - cell.p2, cell.p1));
    
    // Rhombus
    d[4] = sdRhombus(p + cell.p1, abs(cell.p2 + cell.p1));
    
    // Equilateral   
    d[5] = sdEquilateralTriangle(p - cell.p1 * 0.5 - cell.p2 * .5);
    
    // Triangle
    d[6] = sdTriangle(p + fx, cell.p1, cell.p2, cell.p1 + cell.p2);
    
    // Hexagram
    d[7] = sdHexagram(p - cell.p1,  abs(cell.p2.y - cell.p2.x) * .2);
    
    // X
    d[8] = sdRoundedX(p - cell.p1, cell.p2.x , 0.0);
    
    // Cross
    d[9] = sdCross(p - cell.p1, abs(cell.p1 - cell.p2), cell.p2.x);
    
    // Weirdness
    d[10] = sdHorseshoe(p - cell.p1, vec2(.2), .25, cell.p2 - cell.p1);
    
    int nextType = (type+1) % 11;
    return mix(d[type], d[nextType], smoothstep(0.4, 0.6, fT));
}

vec3 RemapColor(float factor)
{
	vec3 a = vec3(0.478, 0.500, 0.500);
	vec3 b = vec3(0.500);
	vec3 c = vec3(0.688, 0.748, 0.748);
	vec3 d = vec3(0.318, 0.588, 0.908);

	return palette(factor, a, b, c, d);
}

vec4 Voronoi(vec2 p)
{
	vec2 flP = floor(p);
    vec2 frP = fract(p);
    
    // f.x: min, f.y: second mininum, etc
    vec4 f = vec4(15.0);
    
    float anisotropy = iMouse.y * 2.0 / iResolution.y;
    float anisoAngle = iMouse.x * 3.141592 / iResolution.x;
    
    for(int x = -4; x <= 4; ++x)
    for(int y = -4; y <= 4; ++y)
    {   
        vec2 offset = vec2(x,y);
        
        float angleRand = hash12(flP + offset) * 3.1415 * 2.0 * RANDOM_ANISOTROPY;
        vec2 anisoOffset = vec2(cos(anisoAngle+angleRand), sin(anisoAngle+angleRand)) * anisotropy;
        
		CellData cell = Sample(flP, offset, anisoOffset);
        
        float dist = SDF(frP, cell, 0.0);

        if(dist < f.x)
        {
            f.w = f.z;
            f.z = f.y;
            f.y = f.x;
            f.x = dist;
        }
	}

    return f;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.y;

    vec4 v = Voronoi((uv+iTime * .05) * 10.0);
    vec3 result = vec3(1.0);
    
    if(fragCoord.x/iResolution.x > 0.66)
    {
        result = RemapColor(v.x);
    }
    else if(fragCoord.x/iResolution.x > 0.33)
    {
        result = RemapColor(v.w);
    }
    else
    {
    	result *= smoothstep(.05, .1, v.y - v.x);
    }
    
    
    fragColor = vec4(result, 1.0);
}