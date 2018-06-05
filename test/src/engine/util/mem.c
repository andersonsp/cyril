#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

typedef struct {
    uint8_t *start, *end, *current;
    uint32_t alloc_id;
} CyStackMem;

CyStackMem* cy_stack_mem_init(void* mem, size_t bytes);
void* cy_stack_mem_alloc(CyStackMem* s, size_t size);
int cy_stack_mem_free(CyStackMem* s, void* p);

#define MEM_BLOCK 1024 * 1024 * 4  // 4MB

int main() {
    void* mem = malloc(MEM_BLOCK);

    CyStackMem* s = cy_stack_mem_init(mem, MEM_BLOCK);

    int32_t *i, *j, *k;

    assert(s->alloc_id == 0);
    i = cy_stack_mem_alloc(s, sizeof(int32_t));
    assert(s->alloc_id == 1);
    j = cy_stack_mem_alloc(s, sizeof(int32_t));
    assert(s->alloc_id == 2);
    k = cy_stack_mem_alloc(s, sizeof(int32_t));
    assert(s->alloc_id == 3);

    *i = 1;
    *j = 2;
    *k = 3;

    cy_stack_mem_free(s, k); // ok
    assert(s->alloc_id == 2);

    cy_stack_mem_free(s, i); // out of order, not freed
    assert(s->alloc_id == 2);

    cy_stack_mem_free(s, j); // ok
    assert(s->alloc_id == 1);

    cy_stack_mem_free(s, i); // now it's correct
    assert(s->alloc_id == 0);

    return 0;
}

