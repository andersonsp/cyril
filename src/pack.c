#include "cyril.h"

typedef struct {
  int32_t magic, version, offset, size;
} PakHeader;

typedef struct {
  char name[56];
  int32_t offset, size;
} CyPakDirEntry;

typedef struct _CyPak {
    CyPakDirEntry *dir;
    int32_t file_size;
    int16_t num_entries;
    uint8_t data[2]; // arrays cannot be 0 length
} CyPak;

CyPak* cy_pak_load(char* filename) {
  PakHeader header;
  FILE *fp = fopen(filename, "rb");
  if (!fp) return NULL;
  if (!fread(&header, sizeof(PakHeader), 1, fp)) goto pak_error;
  if (memcmp(&header.magic, "CYPK", 4) != 0) goto pak_error;
  if (header.version != 1) goto pak_error;

  int data_sz = header.offset + header.size;
  CyPak *res = malloc(sizeof(CyPak) + data_sz);
  if(!res) goto pak_error;
  if (!fread(res->data, sizeof(uint8_t), data_sz, fp)) goto pak_error;

  res->file_size = data_sz + sizeof(PakHeader);
  res->dir = (CyPakDirEntry*) (res->data + header.offset);
  res->num_entries = header.size / sizeof(CyPakDirEntry);

  return res;
 pak_error:
  fclose(fp);
  return NULL;
}

CyPakEntry* cy_pak_get(CyPak* pak, char* path) {
  if(!pak) return NULL;
  for(int i=0; i < pak->num_entries; i++) {
    if(strncmp(path, pak->dir[i].name, 56) == 0) return (CyPakEntry*) (pak->data + pak->dir[i].offset);
  }
  return NULL;
}

void pak_print_stats(CyPak* pak) {
  printf("Pak Size: %d\n", pak->file_size);
  printf("Num files: %d\n", pak->num_entries);

  printf("%-8s %-56s %-8s\n", "Addr", "File name", "Size");
  for(int i = 0; i < pak->num_entries; i++) {
    printf("[%6d] %-56s %7db\n", pak->dir[i].offset, pak->dir[i].name, pak->dir[i].size);
  }
}
