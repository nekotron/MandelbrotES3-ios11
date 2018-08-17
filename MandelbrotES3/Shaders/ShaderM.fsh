#version 300 es
//
//  Shader.fsh
//  MandlebrotES3
//
//  Created by Justin Fleischauer on 2016/10/13.
//  Copyright (c) 2016年 Justin Fleischauer. All rights reserved.
//
//Partially inspired by code seen at www.shadertoy.com/view/XsfGWS


in highp vec2 positionVarying;

out mediump vec4 fragColor;

uniform highp float scaleFactor;
uniform highp float aspectFactor;
uniform highp vec2 moveParams;

precision highp float;

void main(void)
{
  highp vec2 c = positionVarying;
  
  c.x*=aspectFactor;
  
  c.y = (c.y*2.0);
  c.x = (c.x*2.0);
  
  c *= scaleFactor;
  
  c.x = c.x+moveParams.x;
  c.y = c.y+moveParams.y;
  
  highp vec2 z = vec2(0.0, 0.0);
  mediump vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
  
  for(int i=0;i<160;i++)
  {
    //if dot product is greater than 4 set color and then break
    //else get new z
    //if((dot(z,z) >= 4.0)){set color; break;}
    //z[n+1]=z^2+c       c=(a+bi)|a=x&b=y     (a+bi)^2=(a^2+i*a*b+i*a*b-b^2)=(a^2-b^2+i*(a*b+a*b))=(a^2-b^2+i*2(a*b))
    
    //if we have an exit condition this time
    //set color
    if(dot(z,z) >= 4.0)
    {
      color.g=float(i)/80.0;
      color.b=float(i)/20.0;
      color.r=sin((float(i)/5.0));
      break;
    }
    z = vec2(z.x*z.x - z.y*z.y, 2.0*z.y*z.x) + c;
  }
  
  fragColor = color;
}
