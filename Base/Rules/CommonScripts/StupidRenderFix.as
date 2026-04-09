
void StupidRenderFix()
{
	SColor empty = SColor(0x00000000);
	u16[] v_i = { 0, 1, 2, 2, 3, 0 };
	Vertex[] v_raw_dumb;
	v_raw_dumb.push_back(Vertex(Vec2f(0, 0), 1000, Vec2f(0, 0), empty));
	v_raw_dumb.push_back(Vertex(Vec2f(1, 0), 1000, Vec2f(1, 0), empty));
	v_raw_dumb.push_back(Vertex(Vec2f(1, 1), 1000, Vec2f(1, 1), empty));
	v_raw_dumb.push_back(Vertex(Vec2f(0, 1), 1000, Vec2f(0, 1), empty));
	Render::RawTrianglesIndexed("pixel", v_raw_dumb, v_i);
}