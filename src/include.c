#include <sys/stat.h>
#include <stdio.h>
#include <stddef.h>

#define STAT_SIZE sizeof(struct stat)
#define STAT_FS_OFFSET offsetof(struct stat, st_size)

int main() {
  printf("#define STAT_SIZE %lu\n", STAT_SIZE);
  printf("#define STAT_FS_OFFSET %lu\n", STAT_FS_OFFSET);
}
