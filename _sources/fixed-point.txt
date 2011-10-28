Performing fixed point arithmetic
=================================

The XS1 has a series of instructions to aid in the implementation of
fixed point arithmetic. The natively supported format is a 32 bit fixed
point number with the binary point in some arbitrary (user defined)
place. Both signed and unsigned fixed point numbers are supported.

Single word arithmetic
----------------------

Single word arithmetic uses a single 32-bit word to represent a number.

Representation
..............

Unsigned fixed point numbers are stored as a 32-bit number. The value of
the fixed point number is the integer interpretation of the 32-bit value
multiplied by an exponent :math:`2^e` where :math:`e` is a user-defined
fixed number, usually between -32 and 0 inclusive. For example, if
:math:`e` is chosen to be -32, then numbers between 0 and 1 (exclusive) in
steps of approximately :math:`2.3 \cdot 10^{-10}` can be stored; and if :math:`e`
is chosen to be -10, then numbers between 0 and 4,194,304 in steps of
0.0009765625 can be represented.

Signed fixed point numbers are stored in two's complement as a 32-bit
number. The value of the fixed point number is the two's complement
interpretation of the bit pattern multiplied by an exponent :math:`2^e` where :math:`e` is a
user-defined fixed number, usually between -31 and 0 inclusive. For
example, if :math:`e` is chosen to be -31, then numbers between -1 and 1
(exclusive) in steps of approximately :math:`4.6 \cdot 10^{-10}` can be stored; and
if :math:`e` is chosen to be -10, then numbers between -2,097,152 and
2,097,151 in steps of 0.0009765625 can be represented.

We use the notation X.Y to denote the precision, where X is the number of
bits before the binary point, and Y is the number of bits after the binary
point. Hence, :math:`e=-Y`, and :math:`X+Y=32`. For example, the value one
is represented in 8.24 by bit pattern ``0x01000000``, and in 16.16 by bit
pattern ``0x00010000``.

Each variable in a program has at any stage an exponent associated with it.
These exponents have to be known to the programmer, but do not have to be
the same everywhere. We will give some examples later.

Arithmetic
..........

Single length addition and subtraction are performed by integer
arithmetic, provided that the exponent on the left and the right operand
are identical. If the exponents are different, then operand with the lowest
exponent needs to be shifted right prior to the addition, in order to level
the exponents. For example, if one number is represented as 8.24 and the
other number as 16.16, then the first number must be shifted right 8 places
prior to performing the addition or subtraction.
Shifting a number right will cause a rounding error, see below
on how implement rounding.

A multiplication of two numbers with representations X.Y and P.Q will result
in a number with representation X+P.Y+Q; this number will not fit in a 32
bit result. The XS1 can compute the full precision answer using a ``MACCS``
instruction, and then allows the programmer to select the part of the word
that they are interested in, by slicing the appropriate bits out of the answer.

Where a sequence of multiply accumulate operations is performed, the
programmer would normally ensure that all results are represented in the
same X+P.Y+Q format, and hence only at the end of the whole sequence are
the appropriate bits sliced out of the final answer.

Divisions can be performed by a sequence of two long division instructions,
assuming that the sign bit is computed separately.

Rounding
........

Rounding is required both after a multiplication, or prior to addition and
subtraction of values with different exponents.

The principal of rounding is to increment the final result by one, if the
most significant bit that was truncated was ``1``. This can be implemented
efficiently by adding a value prior to truncation. For example, if the last
eight bits are going to be thrown away, then adding ``0x80`` prior to the
shift will implement a rounding operation.

In the case of multiplication operations, rounding can be
implemented by initialising the accumulator of the ``MACCS`` instruction to
0.5 rather than 0. For example, if afterwards the middle 32 bits of two
32-bit words are to be selected, one would set the initial accumulator
low word to 0x8000 to implement rounding.

Other rounding methods, such as dithering, can be implemented by
initialising the accumulator to a value between 0 and 0xFFFF, with an
appropriate PDF. See the chapter on pseudo random numbers.

Overflow and Saturation
.......................

Each time that 32 bits are selected from a 64 bit result, an
overflow may occur. If overflow should be dealt with, then the high word of
the result should be checked for overflow.

An overflow check can be implemented efficiently by checking whether sign
extension is a no-op::

  overflow = sext(x,24) != x;

If a ``sext`` operation changes the number, then the number cannot be
represented in the specified number of bits, indicating an overflow
condition. For unsigned numbers ``zext`` is used.

The only operations that checks on overflow are LADD, LSUB, and LMUL. MACCU
and MACCS do not check on overflow. A combination of LADD and MACCU can be
used to implement a multiply-accumulate that checks for overflow as
follows::

  // adds h:l to a*b leaves result in h:l and flags in overflow:
  int overflow, x = 0;
  {x,l} = mac(a, b, x, l)
  asm("ladd %0, %1, %2, %3, %4" : "=r"(overflow), "=r"(h) : "r"(x), "r"(h), "r"(0))


Example code sequence
.....................

An example to illustrate formats and conversions is shown below::

  int h; unsigned l;
  int a = 0x0010000; // 1.0 in 16.16 format
  int b = 0x0004000; // 0.25 in 16.16 format
  int c = 0x0000100; // 1.0 in 24.8 format
  a = a + b;         // a is still in 16.16 format
  a = a >> 8;        // a is in 24.8 format
  a = a - c;         // a is in 24.8 format
  {h,l} = macs(a, b, 0, 0);    // {h,l} is in 40.24 format, ie, l is
                               // in 8.24 and h is in 40.-8
  if (sext(h, 8) == h) {
      a = h << 24 | l >> 8; // this is in 16.16 format once again.
  } 
  if (h > 0) {
      a = 0x7fffffff;
  } else {
      a = 0x80000000;
  }

A more realistic example implements a FIR filter as follows::

  int fir(int inp[16], int filter[16]) { // 8.24 and 8.24  |filter[x]| < 1
      int h = 0;
      unsigned l = 0x800000;
      for(int i = 0; i < 16; i++) {
          {h,l} = macs(inp[i], filter[i], h, l);
      }
      if (sext(h, 8) == h) {
          return h << 8 | l >> 24;
      }
      if (h > 0) {
          return 0x7fffffff;
      } else {
          return 0x80000000;
      }
  }

This example performs 16 MAC operations followed by a single saturation
test. Note that the MAC operations cannot overflow since there is 7 bits of
headroom in the filter-array.

Multi-word arithmetic
---------------------

Values that require a higher precision (64, 96, or more bits)
can be represented in multiple words,
and operated on by LADD, LMUL, LSUB and LDIV instructions.

The representation can either be signed magnitude, or two's complement.
Signed magnitude is easier for multiplications and divisions, two's
complement is easier for add and subtract.

Assuming unsigned arithmetic (and leaving the signed case to the reader),
the code for an addition of a 64-bit number is::

  LADD c, f, a, b, 0
  LADD c, g, d, e, c

A multiplication of two 64-bit numbers comprises 4 LMUL instructions.
Division of a 64-bit number by a 32-bit number comprises three LDIV
instructions. More instructions are required if numbers are signed, and if
they are represented in two's complement.

Long shift instructions have to be implemented using shift- and
or-instructions::

  {int,unsigned} static inline lshl(int h, unsigned l, int n) {
    return { (h << n) | (l >> (32 - n)), l << n };
  }

  {int,unsigned} static inline lshr(int h, unsigned l, int n) {
    return { h >> n, (l >> n) | (h << (32 - n)) };
  }

These take six instructions each.

