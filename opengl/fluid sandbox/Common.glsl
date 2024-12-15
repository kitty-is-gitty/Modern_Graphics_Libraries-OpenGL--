// THE FELOWWING MUST BE MODFIED IN ALL BUFFER AND IMAGE (until macro)


//Select scheme to do backward advection
//#define EULER
#define RUNGE

// radius of obstacle 
#define radiusObs 0.03

// simulation parameters
const float dt = 1.0/500.0; //time-stepping
const vec2 force = vec2(0., 0.); //constant pressure gradiant flow
const float reynold = 25000.0; //constant defining the flow ~high=water, ~low=vscous
							 //large reynold number, diffuse substance faster.

const float flowSpeed = 4.0; // max speed of flow
const float source = 1.0; //source density
const float kappa = 0.0; //substance diffusion constant
const float alpha = 0.1; //substance dissipation rate

const int bandNb = 20; //number of die line
const int bandDens = 6; //density of die line (high mean less dense)

// Keyboard
const int KEY_ONE  = 49;
const int KEY_TWO  = 50;
const int KEY_THREE  = 51;
const int KEY_FOUR  = 52;
const int KEY_FIVE  = 53;

const int KEY_SPACE  = 32;
const int KEY_C  = 67;

const float epsilon = 30.0;