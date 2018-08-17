#version 300 es
//
//  Shader.vsh
//  MandlebrotES3
//
//  Created by Justin Fleischauer on 2016/10/13.
//  Copyright (c) 2016年 Justin Fleischauer. All rights reserved.
//

precision highp float;

in vec4 position;
in vec4 color;

out highp vec2 positionVarying;

uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;

invariant positionVarying;

void main()
{
  positionVarying = position.xy;

  gl_Position = position;
}
