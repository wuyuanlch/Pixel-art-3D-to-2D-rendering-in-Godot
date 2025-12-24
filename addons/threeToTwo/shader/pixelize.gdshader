shader_type canvas_item;

uniform vec2 pixel_count=vec2(64);


void fragment() {
	vec2 uv =UV;

	uv*=pixel_count;
	uv=floor(uv);
	uv/=pixel_count;

	COLOR=texture(TEXTURE,uv);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
