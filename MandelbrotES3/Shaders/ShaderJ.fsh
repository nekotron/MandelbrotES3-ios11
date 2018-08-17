#version 300 es
//
//  Shader.fsh
//  MandlebrotES3
//
//  Created by Justin Fleischauer on 2016/10/13.
//  Copyright (c) 2016年 Justin Fleischauer. All rights reserved.
//

in highp vec2 positionVarying;

out lowp vec4 fragColor;

uniform highp float scaleFactor;
uniform highp float aspectFactor;
uniform highp vec2 moveParams;
uniform highp vec2 setParams;

precision highp float;

void main(void)
{
  highp vec2 z = positionVarying;
  highp vec2 c = vec2(-1.0, 0.0);
  mediump vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
  
  c = setParams;
  
  z.x *= aspectFactor;
  
  z *= 2.0;
  
  z *= scaleFactor;
  
  z.x = z.x+moveParams.x;
  z.y = z.y+moveParams.y;
  
  for(int i=0;i<160;i++)
  {
    
    //if dot product is greater than 4 exit condition is met, set color and break
    //else get new z
    //if((dot(z,z) >= 4.0)){doColor;break;}
    //z[n+1]=z^2+c       c=(a+bi)|a=x&b=y     (a+bi)^2=(a^2+i*a*b+i*a*b-b^2)=(a^2-b^2+i*(a*b+a*b))=(a^2-b^2+i*2(a*b))
    
    if(dot(z,z) >= 4.0)
    {
      color.g=float(i)/80.0;
      color.b=float(i)/20.0;
      color.r=sin((float(i+1)/5.0));
      break;
    }
    z = vec2(z.x*z.x - z.y*z.y, 2.0*z.y*z.x) + c;
  }
  fragColor = color;
}
