Pseudo Random Numbers
=====================

An app-note describes how to generate random numbers using the CRC
instruction, and how to generate real random numbers [xmosrandom]_. In short, a
pseudo random sequence can be generated using the CRC instruction and a
suitable polynomial.

For specific purposes, random numbers may need to have a specific
distribution. As an example, we show here how to make a pseudo random
number generator that generates random values with a Triangular
Probability Density Function (TPDF), used in, for example, audio dithering. 

Below is the code to generate those numbers. It generates a 32-bit pseudo random
number, takes the bottom and top bits, sums those, and normalises it
around 0. It generates random numbers in the range *[1..2^(2B)-1]*, with a
PDF *P(x) = 2^(-B)-2^(-2B)|x-2^B+1|*::

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

This value can, for example, be used to initialise the accumulator prior to
performing a series of multiply accumulate operations.
