// Zimmer Code 
//+++++++++++++++++++++++++++++
//external parameters, do not modify
//+++++++++++++++++++++++++++++
//keyboard controlled temporary variables (in some versions exists in the config file). Press and hold key 1,2,3...8 together with PageUp or PageDown to modify. By default all set to 1.0
float4 tempF1; //0,1,2,3 
float4 tempF2; //5,6,7,8 
float4 tempF3; //9,0
//x=Width, y=1/Width, z=ScreenScaleY, w=1/ScreenScaleY
float4 ScreenSize;
//x=generic timer in range 0..1, period of 16777216 ms (4.6 hours), w=frame time elapsed (in seconds)
float4 Timer;
//changes in range 0..1, 0 means that night time, 1 - day time
float ENightDayFactor;
//changes 0 or 1. 0 means that exterior, 1 - interior
float EInteriorFactor;
//.x - current weather index, .y - incoming weather index, .z - weather transition, .w - time of the day in 24 standart hours. Weather index is value from _weatherlist.ini, for example WEATHER002 means index==2, but index==0 means that weather not captured.
float4 WeatherAndTime;
//adaptation delta time for focusing
float FadeFactor;
//fov in degrees
float FieldOfView;
//time in 0..24 format
float GameTime;
//sun direction in world space
float4 SunDirection; //.w - 1 when sun is set
//constants set in enbhelper.dll, can be anything captured from game
float4 CustomShaderConstants1[8];

//transposed transform matrix view*projection and inverse of it
float4 MatrixVP[4];
float4 MatrixInverseVP[4];
float4 MatrixVPRotation[4];
float4 MatrixInverseVPRotation[4];
float4 MatrixView[4];
float4 MatrixInverseView[4];
float4 CameraPosition;

float4 PrevMatrixVPRotation[4];
float4 PrevMatrixInverseVPRotation[4];
float4 PrevCameraPosition;

float EnableDepthOfField;
float EnableMotionBlur;

//textures
texture2D texOriginal; 
texture2D texColor;
texture2D texDepth;
texture2D texNormal;
texture2D texEnv;
texture2D texNoise;
texture2D texPalette;
texture2D texFocus;
texture2D texCurr;
texture2D texPrev;

sampler2D SamplerOriginal = sampler_state
{
	Texture   = <texOriginal>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerColor = sampler_state
{
	Texture   = <texColor>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerDepth = sampler_state
{
	Texture   = <texDepth>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerNormal = sampler_state
{
	Texture   = <texNormal>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerEnv = sampler_state
{
	Texture   = <texEnv>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerNoise = sampler_state
{
	Texture   = <texNoise>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU  = Wrap;
	AddressV  = Wrap;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerPalette = sampler_state
{
	Texture   = <texPalette>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerCurr = sampler_state
{
	Texture   = <texCurr>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerPrev = sampler_state
{
	Texture   = <texPrev>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerFocus = sampler_state
{
	Texture   = <texFocus>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

struct VS_OUTPUT_POST
{
	float4 vpos  : POSITION;
	float2 txcoord : TEXCOORD0;
};

struct VS_INPUT_POST
{
	float3 pos  : POSITION;
	float2 txcoord : TEXCOORD0;
};

float EMotionBlurStepsInv
<
	string UIName="EMotionBlurStepsInv";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=100.0;
> = {0.25};

#define rings 3 
#define samples 9 

float CoC
<
	string UIName="CoC";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=100.0;
> = {0.5};

float FocalLength
<
	string UIName="Focal - Length";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=100.0;
> = {0.5};

float  FocusX
<
	string UIName="FocusX";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=100.0;
> = {0.5};

float  FocusY
<
	string UIName="FocusY";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=100.0;
> = {0.5};

bool BokehBias
<
         string UIName="BokehBias";	
> = {true};


float BlurDist
<
	string UIName="BlurDist";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=100.0;
> = {1.3};

float BlurRadialFade
<
	string UIName="BlurDist";
	string UIWidget="Spinner";
	float UIMin=0.0;
	float UIMax=100.0;
> = {0.1};

VS_OUTPUT_POST VS_PostProcess(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST OUT;
	float4 pos = float4(IN.pos.x,IN.pos.y,IN.pos.z,1.0);
	if (EnableMotionBlur==0.0) pos.xy = 10000.0;
	OUT.vpos = pos;
	OUT.txcoord.xy = IN.txcoord.xy;
	return OUT;
}


float FuncMasking(float4 uv)
{
	float mask = tex2Dlod(SamplerNormal, uv).w;
	if ((mask>=(50.0/255.0)) && (mask!=1.0))
		mask=0.0;
	else mask = 1.0;
	return mask;
}

float linearize(float nonLinDepth)
{ 
float Z_near = 0.3;
float Z_far = 100.0; 
return -Z_far * Z_near / (nonLinDepth * (Z_far - Z_near) - Z_far);
}

float4 PS_ReadFocus(VS_OUTPUT_POST IN) : COLOR
{
	float2 FocusPoint=float2(FocusX, FocusY);

	float Result=linearize(tex2D(SamplerDepth, FocusPoint.xy)).x;

	return Result;
}

float4 PS_WriteFocus(VS_OUTPUT_POST IN) : COLOR
{
	float2 FocusPoint=float2(FocusX, FocusY);
	
	float	Current=tex2D(SamplerCurr, FocusPoint).x;
	float	Previous=tex2D(SamplerPrev, FocusPoint).x;
	
	float Result=lerp(Previous, Current, saturate(FadeFactor));

	return Result;
}

////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////

float4 PS_MotionBlur(VS_OUTPUT_POST IN, float2 vPos : VPOS) : COLOR
{
	float4	res;
	float4	coord;
	coord.xy=IN.txcoord.xy;
	coord.zw=0.0;
    float seed = 0.0;
	float4	color=tex2D(SamplerOriginal, IN.txcoord.xy);
	color.xyz*=color.xyz;
	float	scenedepth=tex2D(SamplerDepth, IN.txcoord.xy).x;
	float4	tempvec;
	float4	temppos;
	float4	worldpos;
	float4	wpos;	
	float4	prevworldpos;
	float4	prevscreen;
	float4	currscreen;
	currscreen.xy=IN.txcoord.xy;

	tempvec.xy=IN.txcoord.xy*2.0-1.0;
	tempvec.y=-tempvec.y;
	tempvec.z=scenedepth;
	tempvec.w=1.0;

	worldpos.x=dot(tempvec, MatrixInverseVPRotation[0]);
	worldpos.y=dot(tempvec, MatrixInverseVPRotation[1]);
	worldpos.z=dot(tempvec, MatrixInverseVPRotation[2]);
	worldpos.w=dot(tempvec, MatrixInverseVPRotation[3]);
	worldpos.xyz/=worldpos.w;
	
    wpos.x = dot(tempvec, MatrixInverseVPRotation[0]);
    wpos.y = dot(tempvec, MatrixInverseVPRotation[1]);
    wpos.z = dot(tempvec, MatrixInverseVPRotation[2]);
    wpos.w = dot(tempvec, MatrixInverseVPRotation[3]);
    wpos.xyz/= wpos.w;	
   
    float4 wp = wpos;
    float pow2 = length(wp.xyz);
    float distance = 0.0;
    float3 dp1 = -1.0/exp(length(distance-pow2)/(2.0*0.48)); 		 

	float	distfact=dot(worldpos.xyz, worldpos.xyz);
	distfact=saturate(distfact*0.0002);
	distfact*=distfact;
	
	float	distfact2=dot(worldpos.xyz, worldpos.xyz);
	distfact2=saturate(distfact2*0.0002);
	distfact2*=distfact2;
	distfact2 = pow(distfact2, 117000000.0*24.50);
	distfact2 = lerp(1.0, distfact2, dp1); 
	
    float4 vfog2 = pow(distfact2, -1000000.0*24.50);	
   
	worldpos.xyz+=CameraPosition;
	prevworldpos.x=dot(tempvec, PrevMatrixInverseVPRotation[0]);
	prevworldpos.y=dot(tempvec, PrevMatrixInverseVPRotation[1]);
	prevworldpos.z=dot(tempvec, PrevMatrixInverseVPRotation[2]);
	prevworldpos.w=dot(tempvec, PrevMatrixInverseVPRotation[3]);
	prevworldpos.xyz/=prevworldpos.w;

	prevworldpos.xyz+=PrevCameraPosition;

	float3 dir;
	dir = (worldpos.xyz-prevworldpos.xyz);
	dir = dir * 0.70;
	prevworldpos.xyz = prevworldpos.xyz+dir.xyz;

	tempvec.xyz=prevworldpos.xyz;
	tempvec.w=1.0;
	prevscreen.x=dot(tempvec, MatrixVP[0]);
	prevscreen.y=dot(tempvec, MatrixVP[1]);
	prevscreen.z=dot(tempvec, MatrixVP[2]);
	prevscreen.w=dot(tempvec, MatrixVP[3]);
	prevscreen.xyz/=prevscreen.w;
	prevscreen.xy=prevscreen.xy*float2(0.5,-0.5) + 0.5;
	prevscreen.z=1.0/max(1.0-prevscreen.z, 0.0000000000001);
	currscreen.z=1.0/max(1.0-scenedepth, 0.0000000000001);

	float mask;
	      mask=FuncMasking(coord);		  
	float4 no1 = tex2Dlod(SamplerNormal, coord).w;	
	if (no1.x>=(25.0/1.0)) no1.z=24.50;	
	float2	jitteruv;
	        jitteruv=frac((vPos.xy+seed)*0.0625)+0.03125;
	float4	jitter=tex2D(SamplerNoise, jitteruv);
	float	step=-0.20*EMotionBlurStepsInv;	        
	float	shift=step*jitter.y;
	float	weight=1.0;
	int		i=0;
	while ((shift<1.0) && (i<12))
	{
		i++;
		float	tempmask;		
		float4	tempcolor;
		float	tempweight;
		coord.xyz=lerp(currscreen.xyz, prevscreen.xyz, shift);

		tempmask=FuncMasking(coord);

		if (mask==0.0)
		{
			float	tempdepth=tex2Dlod(SamplerDepth, coord).x;
			tempdepth=1.0/max(1.0-tempdepth, 0.0000000000001);
			tempmask*=saturate((coord.z-tempdepth)*1000.0);
		}

		tempmask=saturate(tempmask+vfog2);
		shift+=step;
		float2	uvfact=saturate(-coord.xy)+saturate(coord.xy-1.0);
		uvfact.x+=uvfact.y;
		tempmask=saturate(tempmask - uvfact.x*100000.0);

		tempcolor=tex2Dlod(SamplerColor, coord);
		tempcolor.xyz*=tempcolor.xyz;

		color+=tempcolor * tempmask;
		weight+=tempmask;
	}
	color/=weight;
	color.xyz=pow(color.xyz, 0.5);
	res.xyz=color;
	res.w=1.0;
	return res;
}

float4 PS_DoF(VS_OUTPUT_POST IN): COLOR
{
	float4 Color = tex2D(SamplerColor, IN.txcoord);

	if (EnableDepthOfField == 1.0)
	{
	float Depth = linearize(tex2D(SamplerDepth,IN.txcoord.xy).x);
	
	float FDepth = tex2D(SamplerFocus,float2(FocusX,FocusY)).x;

	float Blur = 0.0;
	
	float a = (Depth * FocalLength)/(Depth - FocalLength); 
	float b = (FDepth * FocalLength)/(FDepth - FocalLength); 
	float c = (FDepth - FocalLength)/(FDepth * CoC); 
	
	Blur = abs(a-b)*c;
	
	if(Depth < FDepth)
	{
	float BlurRadialDist = distance(IN.txcoord.xy, float2(FocusX,FocusY));
	BlurRadialDist = smoothstep(0.0, Blur + (1.0/BlurRadialFade), BlurRadialDist);
	Blur *= clamp(BlurRadialDist,0.0,1.0);
	}

	Blur = clamp(Blur,0.0,1.0); 
	
	float w = ScreenSize.y * Blur * BlurDist;
	float h = ScreenSize.y * ScreenSize.z * Blur * BlurDist;
	
	float s = 1.0; 
	
	[unroll]
	for (int i = 1; i <= rings; i += 1)
	{
	int ringsamples = i*samples;
	[unroll]
	for (int j = 0 ; j < ringsamples ; j += 1) 
	{
	float Cpoint = 3.1415 * 2.0 / float(ringsamples);
	float pw = (cos(float(j)*Cpoint) * float(i));
	float ph = (sin(float(j)*Cpoint) * float(i));
	
	Color +=  tex2D(SamplerColor, IN.txcoord.xy + float2(pw*w, ph*h) * Blur) * lerp(1.0, (float(i) / float(rings)) * 25.0, BokehBias);
				
	s += 1.0 * lerp(1.0, (float(i) / float(rings)) * 25.0, BokehBias); 			

 	}
}
	Color /= s; 
}
		
	return float4(Color.xyz,1.0); 
}

////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////

technique ReadFocus
{
	pass P0
	{
		VertexShader = compile vs_3_0 VS_PostProcess();
		PixelShader  = compile ps_3_0 PS_ReadFocus();
		
	}
}

technique WriteFocus
{
	pass P0
	{
		VertexShader = compile vs_3_0 VS_PostProcess();
		PixelShader  = compile ps_3_0 PS_WriteFocus();

	}
}

technique PostProcess
{
	pass p0
	{
		VertexShader = compile vs_3_0 VS_PostProcess();
		PixelShader  = compile ps_3_0 PS_MotionBlur();
	}
}

technique PostProcess2
{
	pass p0
	{
		VertexShader = compile vs_3_0 VS_PostProcess();
		PixelShader  = compile ps_3_0 PS_DoF();
	}
}