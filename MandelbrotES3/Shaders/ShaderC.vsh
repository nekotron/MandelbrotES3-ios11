#version 300 es
//
//  Shader.vsh
//  MandlebrotES3
//
//  Created by Justin Fleischauer on 2016/10/13.
//  Copyright (c) 2016年 Justin Fleischauer. All rights reserved.
//  This is the vertex shader which allows display of the two sets on the third screen

in vec4 position;
in vec2 textureUV;

out lowp vec2 texVarying;

void main()
{
  texVarying = textureUV;             // Linear interpolation for the win
  gl_Position = position;
}
