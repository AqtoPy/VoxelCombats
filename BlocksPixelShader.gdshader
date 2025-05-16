shader_type spatial;

uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float roughness = 0.8;

void fragment() {
    ALBEDO = albedo.rgb;
    ROUGHNESS = roughness;
    METALLIC = 0.0;
    SPECULAR = 0.1;
}
