

//3D
// Sphere
// s: radius
float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) +
		length(max(d, 0.0));
}

//draw a plane
float sdPlane(float3 p, float3 n, float h)
{
	// n must be normalized
	return dot(p, n) + h;
}

float sdRoundBox(float3 p, float3 b, float r)
{
	float3 q = abs(p) - b;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

// BOOLEAN OPERATORS //

// Union
float opU(float d1, float d2)
{
	return min(d1, d2);
}

float opUS(float a, float b, float k)
{
	float h = max(k - abs(a - b), 0.0) / k;
	return min(a, b) - h * h * k * (1.0 / 4.0);
}

// Subtraction
float opS(float d1, float d2)
{
	return max(-d1, d2);
}

float opSS(float d1, float d2, float k)
{
	float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0, 1);
	return lerp(d2, -d1, h) + k * h * (1 - h);
}

// Intersection
float opI(float d1, float d2)
{
	return max(d1, d2);
}

float opIS(float d1, float d2, float k)
{
	float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0, 1);
	return lerp(d2, d1, h) + k * h * (1 - h);
}

// Mod Position Axis
float pMod1 (inout float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p+halfsize)/size);
	p = fmod(p+halfsize,size)-halfsize;
	p = fmod(-p+halfsize,size)-halfsize;
	return c;
}




//2D
float sdCircle(float2 p,  float r)
{
	return length(p) - r;
}


