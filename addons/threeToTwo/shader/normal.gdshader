shader_type spatial;
render_mode unshaded;

void fragment() {
    // 默认设置为紫色背景 (0.5, 0.5, 1.0)
    ALBEDO = vec3(0.5, 0.5, 1.0);

    // 如果有有效的法线信息，则覆盖为法线颜色
    if (length(NORMAL) > 0.0) {
        // 将法线向量从[-1,1]映射到[0,1]
        vec3 normal = NORMAL * 0.5 + 0.5;
        ALBEDO = normal;
    }
}
