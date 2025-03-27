
class HeapElement {
    u16 priority;
    u16 cost;
    Vec2f pos;
    HeapElement@ parent;

    HeapElement(u16 _priority, u16 _cost, Vec2f _pos, HeapElement@ _parent) {
        priority = _priority;
        cost = _cost;
        pos = _pos;
        @parent = _parent;
    }
}