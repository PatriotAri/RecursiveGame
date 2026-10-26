shader_type canvas_item;

// Redraws art made as one material as another: each pixel's brightness picks
// a colour along `ramp`, dark to light, so outlines stay dark and highlights
// stay bright. Pixels more colourful than `max_saturation` keep their own
// colour, so a sword's wooden grip stays wood while its blade changes.

uniform sampler2D ramp : repeat_disable;
uniform float max_saturation = 1.0;

// Modulate (a damage flash, a faded icon) arrives in the vertex colour and
// would be lost when the texture is resampled, so it's carried across.
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	float high = max(texel.r, max(texel.g, texel.b));
	float low = min(texel.r, min(texel.g, texel.b));
	float saturation = high > 0.0 ? (high - low) / high : 0.0;
	if (saturation <= max_saturation) {
		float brightness = dot(texel.rgb, vec3(0.299, 0.587, 0.114));
		texel.rgb = texture(ramp, vec2(brightness, 0.5)).rgb;
	}
	COLOR = texel * tint;
}
