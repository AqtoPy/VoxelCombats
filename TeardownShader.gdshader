shader_type canvas_item;

void fragment() {
    vec3 col = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
    
    // Повышение контраста
    col = (col - 0.5) * 1.2 + 0.5;
    
    // Лёгкая десатурация
    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(col, vec3(luma), 0.1);
    
    // Тёплый оттенок
    col.r *= 1.05;
    col.g *= 1.02;
    
    COLOR = vec4(col, 1.0);
}
