shader_type canvas_item;

uniform vec4 inline_color : source_color = vec4(1.0);
uniform float inline_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;

    vec4 tex_col = texture(TEXTURE, UV); // sample texture directly
    float alpha = tex_col.a;

    // Check neighbors (4-neighbor for thin stroke)
    bool near_edge = false;
    near_edge = near_edge || texture(TEXTURE, UV + pixel_size * vec2(1.0, 0.0)).a < 0.6;
    near_edge = near_edge || texture(TEXTURE, UV + pixel_size * vec2(-1.0, 0.0)).a < 0.6;
    near_edge = near_edge || texture(TEXTURE, UV + pixel_size * vec2(0.0, 1.0)).a < 0.6;
    near_edge = near_edge || texture(TEXTURE, UV + pixel_size * vec2(0.0, -1.0)).a < 0.6;

    // Inline condition: pixel is filled but close to transparent
    bool is_inline = (alpha > 0.5) && near_edge;

    // Convert bool to float for mix
    float factor = is_inline ? 1.0 : 0.0;

    // Blend texture color with inline color
    COLOR = mix(tex_col, inline_color, factor * inline_strength);
}
