// Based on https://github.com/google/sanitizers/wiki/MemorySanitizer#using-memorysanitizer
#include <cstdio>

int main(int argc, [[maybe_unused]] char** argv) {
   int* a = new int[10];
   a[5] = 0;
   if (a[argc])
      printf("xx\n");
   return 0;
}
