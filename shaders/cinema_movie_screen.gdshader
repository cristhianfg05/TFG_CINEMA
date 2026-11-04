shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D movie_frame : source_color, filter_linear;
uniform float softness : hint_range(0.0, 1.0) = 0.96;
uniform float blur_radius : hint_range(0.0, 12.0) = 6.5;
uniform float contrast : hint_range(0.8, 1.2) = 0.98;
uniform float screen_aspect = 2.4;
uniform float video_aspect = 1.777778;

void fragment() {
	vec2 movie_uv = UV;
	// Fill the wide cinema canvas by cropping gently rather than stretching faces.
	if (screen_aspect > video_aspect) {
		movie_uv.y = 0.5 + (UV.y - 0.5) * video_aspect / screen_aspect;
	} else {
		movie_uv.x = 0.5 + (UV.x - 0.5) * screen_aspect / video_aspect;
	}
	vec2 px = blur_radius / vec2(textureSize(movie_frame, 0));
	vec3 centre = texture(movie_frame, movie_uv).rgb;
	vec3 blurred = centre * 0.18;
	blurred += texture(movie_frame, movie_uv + vec2(px.x, 0.0)).rgb * 0.08;
	blurred += texture(movie_frame, movie_uv - vec2(px.x, 0.0)).rgb * 0.08;
	blurred += texture(movie_frame, movie_uv + vec2(0.0, px.y)).rgb * 0.08;
	blurred += texture(movie_frame, movie_uv - vec2(0.0, px.y)).rgb * 0.08;
	blurred += texture(movie_frame, movie_uv + px).rgb * 0.06;
	blurred += texture(movie_frame, movie_uv - px).rgb * 0.06;
	blurred += texture(movie_frame, movie_uv + vec2(px.x, -px.y)).rgb * 0.06;
	blurred += texture(movie_frame, movie_uv + vec2(-px.x, px.y)).rgb * 0.06;
	blurred += texture(movie_frame, movie_uv + vec2(px.x * 2.0, 0.0)).rgb * 0.065;
	blurred += texture(movie_frame, movie_uv - vec2(px.x * 2.0, 0.0)).rgb * 0.065;
	blurred += texture(movie_frame, movie_uv + vec2(0.0, px.y * 2.0)).rgb * 0.065;
	blurred += texture(movie_frame, movie_uv - vec2(0.0, px.y * 2.0)).rgb * 0.065;
	vec3 colour = mix(centre, blurred, softness);
	ALBEDO = clamp((colour - 0.5) * contrast + 0.5, 0.0, 1.0);
	EMISSION = ALBEDO * 0.35;
}
