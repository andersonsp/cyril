#include <stddef.h>
#include <stdint.h>

#define MEM_ALIGN 4  // align to a 4 byte boundary
#define ALLOC_OFFSET sizeof(uint32_t) * 2

typedef struct {
    uint8_t *start, *end, *current;
    uint32_t alloc_id;
} CyStackMem;

CyStackMem* cy_stack_mem_init(void* mem, size_t bytes);
void* cy_stack_mem_alloc(CyStackMem* s, size_t size);
void cy_stack_mem_free(CyStackMem* s, void* p);

CyStackMem* cy_stack_mem_init(void* mem, size_t bytes) {
    // we assume the memory handed to us is valid and properly aligned
    CyStackMem* s = (CyStackMem*) mem;
    s->start = s->current = (uint8_t*)(s+1);
    s->end = ((uint8_t*) mem) + bytes;

    return s;
}

void* cy_stack_mem_alloc(CyStackMem* s, size_t size) {
    uint32_t offset = (uint32_t)(s->current - s->start);

    size += ALLOC_OFFSET; // to add storage for our current offset and alloc_id
    s->current += (- (int64_t)s->current & MEM_ALIGN);

    if(s->current + size > s->end) {
        // OOM
        return NULL; // TODO: this should panic, not return null
    }

    uint8_t* addr =  s->current;
    *((uint32_t*)addr) = offset;
    addr += sizeof(uint32_t);
    *((uint32_t*)addr) = ++s->alloc_id;
    addr += sizeof(uint32_t);

    s->current += size;

    return (void*) addr;
}

void cy_stack_mem_free(CyStackMem* s, void* p) {

    uint8_t* addr =  ((uint8_t*) p) - ALLOC_OFFSET;

    uint32_t offset = *((uint32_t*)addr);
    addr += sizeof(uint32_t);
    uint32_t id = *((uint32_t*)addr);

    if(id != s->alloc_id) {
        return; // do nothing for now
    }
    s->alloc_id--;
    s->current = s->start + offset;
}

