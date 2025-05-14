shader_type spatial;
render_mode unshaded;

void fragment() {
    vec2 uv = UV * 10.0;
    vec2 grid = abs(fract(uv - 0.5) - 0.5);
    float line = smoothstep(0.05, 0.06, min(grid.x, grid.y));
    ALBEDO = vec4(0.5, 0.5, 0.5, 0.2) * line;
}
