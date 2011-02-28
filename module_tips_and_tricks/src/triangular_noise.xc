#define POLYNOMIAL 0xEDB88320
#define B 8

unsigned int seed = 0xffffffff;

int tpdf() {
  int value1, value2;

  crc32(seed, ~0, POLYNOMIAL);
  value1 = seed >> (32-B);
  value2 = seed & ((1<<B)-1);
  return value1 + value2 + 1;
}
