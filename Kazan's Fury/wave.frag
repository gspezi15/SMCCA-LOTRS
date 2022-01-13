#version 120
uniform sampler2D iChannel0;
uniform float iTime;
uniform vec3 iResolution;
uniform sampler2D iMask; //in the lua I pass the img
uniform float intensity;

//Make


void main()
{
    
	vec4 c = texture2D(iChannel0,gl_TexCoord[0].xy); 

    gl_FragColor = c*gl_Color+vec4(0.3,0,0.,0.1)*c.a;
}