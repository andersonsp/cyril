# Custom formats used


## PAK

The container format used by Land, dubed LPAK, is a derivative version of the Quake 1 Pack format
as described [here](https://quakewiki.org/wiki/.pak), with some extra constraints:

- offsets are relative to the end of the header
- offsets must be multiple of 4
- files are prepended a header with some useful information

### LPAK Specs:

- Header: 12 bytes
  - "LPAK"           4 * int8_t
  - version          int32_t
  - directory offset int32_t
  - directory size   int32_t

- File data
  - Header 4 bytes
    - File size:  int32_t
  - File contents N * uint8_t
  - padding to a 4 byte boundary

- Directory (Num files * 64 bytes)
  - Directory Entries 64 bytes
    - file name     56 * uint8_t
    - file offset   int32_t
    - file size     int32_t
