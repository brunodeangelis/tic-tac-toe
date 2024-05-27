#version 330

#define FOCUS_DETAIL 60

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform float blurIntensity;
uniform float opacity;

out vec4 finalColor;

void main() {
    vec2 mousePos = vec2(0.5, 0.5);
    vec2 focus = fragTexCoord - mousePos;

    vec4 outColor = vec4(0.0, 0.0, 0.0, 1.0);

    for (int i = 0; i < FOCUS_DETAIL; i++) {
        float power = 1.0 - blurIntensity * (1.0 / 800) * float(i);
        outColor.rgb += texture(texture0, focus * power + 0.5).rgb;
    }

    outColor.rgb *= 1.0 / float(FOCUS_DETAIL);
    finalColor = vec4(outColor.rgb * opacity, 1.0);
}
