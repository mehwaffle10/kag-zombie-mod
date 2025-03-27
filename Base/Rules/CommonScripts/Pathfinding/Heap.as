
#include "HeapElement.as"

class MinHeap
{
	HeapElement@[] elements;
	u16 capacity;
	u16 size;

	MinHeap(u16 _capacity)
    {
        size = 0;
        capacity = _capacity;
        HeapElement@[] _elements(_capacity); 
        elements = _elements;
    }

    void Swap(u16 i, u16 j)
    {
        HeapElement@ temp = @elements[i];
        @elements[i] = @elements[j];
        @elements[j] = @temp;
    }

	void MinHeapify(u16 i)
    {
        u16 l = left(i);
        u16 r = right(i);
        u16 smallest = i;
        if (l < size && elements[l].priority < elements[i].priority)
        {
            smallest = l;
        }
        if (r < size && elements[r].priority < elements[smallest].priority)
        {
            smallest = r;
        }
        if (smallest != i)
        {
            Swap(i, smallest);
            MinHeapify(smallest);
        }
    }

	u16 parent(u16 i) {
        return (i - 1) / 2;
    }

	u16 left(u16 i) {
        return (2 * i + 1);
    }

	u16 right(u16 i) {
        return (2 * i + 2);
    }

	HeapElement@ pop()
    {
        if (size <= 0)
        {
            print("Heap is empty");
            return null;
        }

        if (size == 1)
        {
            size--;
            return @elements[0];
        }

        HeapElement@ root = @elements[0];
        @elements[0] = @elements[size - 1];
        size--;
        MinHeapify(0);

        return root;
    }

	void push(HeapElement@ element)
    {
        if (size == capacity)
        {
            print("Can not insert key, heap at max capacity");
            return;
        }

        u16 i = size;
        @elements[i] = element;
        size++;

        while (i != 0 && elements[parent(i)].priority > elements[i].priority)
        {
            Swap(i, parent(i));
            i = parent(i);
        }
    }
};
