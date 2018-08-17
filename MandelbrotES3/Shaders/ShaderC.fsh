#version 300 es
//
//  Shader.fsh
//  MandlebrotES3
//
//  Created by Justin Fleischauer on 2016/10/13.
//  Copyright (c) 2016年 Justin Fleischauer. All rights reserved.
//  This is the fragment shader which allows display of the two sets on the third screen


in lowp vec2 texVarying;   //Where in the texture are we?

out lowp vec4 fragColor;   //The color of the pixel output

uniform sampler2D Texture; //Texture which contains image data for the two sets together

void main()
{
  fragColor = texture(Texture, texVarying);
}
