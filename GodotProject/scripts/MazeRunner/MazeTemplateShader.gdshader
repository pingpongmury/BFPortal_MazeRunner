shader_type spatial;

uniform sampler2D tex : source_color;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 c = texture(tex, UV);
    ALBEDO = vec3(1.0 - c.rgb);
    ALPHA = c.a * opacity;   // adjustable alpha
}