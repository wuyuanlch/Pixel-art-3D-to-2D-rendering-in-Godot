shader_type canvas_item;

// 参数：背景色和阈值
uniform vec3 bg_color : source_color = vec3(0.0, 0.0, 0.0); // 默认黑色背景
uniform float threshold : hint_range(0.0, 1.0) = 0.1; // 颜色匹配阈值
uniform float softness : hint_range(0.0, 0.5) = 0.05; // 边缘柔化

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    // 计算当前颜色与背景色的差异
    float diff = distance(color.rgb, bg_color);
    
    // 使用平滑过渡函数
    float alpha = 1.0 - smoothstep(threshold, threshold + softness, diff);
    
    // 设置输出：保留原始颜色，但将背景色部分设为透明
    COLOR = vec4(color.rgb, color.a * (1.0 - alpha));
}
