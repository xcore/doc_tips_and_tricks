Performing fixed point arithmetic
=================================

The XS1 has a series of instructions to aid in the implementation of
fixed point arithmetic. The natively supported format is a 32 bit fixed
point number with the binary point in some aribitrary (user defined)
place. Both signed and unsigned fixed point numbers are supported.

Single word numbers
-------------------

Representation
..............

Unsigned fixed point numbers are stored as a 32-bit number. The value of
the fixed point number is the integer interpretation of the 32-bit value
multiplied by an exponent :math:`2^e` where :math:`e` is a user-defined
fixed number, usually between -32 and 0 inclusive. For example, if
:math:`e` is chosen to be -32, then numbers between 0 and 1 (exclusive) in
steps of approx :math:`2.3 \cdot 10^{10}` can be stored; and if :math:`e`
is chosen to be -10, then numbers between 0 and 4,194,304 in steps of
0.0009765625 can be represented.

Signed fixed point numbers are stored in two's complement as a 32-bit
number. The value of the fixed point number is the two's complement
interpretation multiplied by an exponent :math:`2^e` where :math:`e` is a
user-defined fixed number, usually between -31 and 0 inclusive. For
example, if :math:`e` is chosen to be -31, then numbers between -1 and 1
(exclusive) in steps of approx :math:`4.6 \cdot 10^{10}` can be stored; and
if :math:`e` is chosen to be -10, then numbers between -2,097,152 and
2,097,151 in steps of 0.0009765625 can be represented.

We use the notation X.Y to denote the precision, where X is the number of
bits before the binary point, and Y is the number of bits after the binary
point. Hence, :math:`e=-Y`, and :math:`X+Y=32`

Each variable in a program has at any stage an exponent associated with it.
These exponents have to be known to the programmer, but do not have to be
the same everywhere. We will give some examples later.

Arithmetic
..........

Single length addition and subtraction can simply be performed by integer
arithmetic, provided that the exponent on the left and the right operand
are identical. If the exponents are different, then operand with the lowest
exponent needs to be shifted right prior to the addition, in order to level
the exponents. For example, if one number is represented as 8.24 and the
other number as 16.16, then the first number must be shifted right 8 places
prior to performing the addition or subtraction.

Shfiting the number right 8 places will cause a rounding error; the final
result can be incremented by if the seventh bit shifted out was a one bit
in order to implement rounding.

Multiplications of two numbers with representations X.Y and P.Q will result
in a number with representation X+P.Y+Q; this number will not fit in a 32
bit result. The XS1 can compute the full precision answer using a ``MACCS``
instruction, and then allows the programmer to select the part of the word
that they are interested in, by picking the right bits out of the answer.

Where a sequence of multiply accumulate operations is performed, the
programmer would normally ensure that all results are represented in the
same X+P.Y+Q format, and hence only at the end of the whole sequence do the
right bits need to be selected.

Divisions can be performed by means of two long division instructions.

Rounding
........

Rounding is typically an issue on multiply operations. Rounding can be
implemented by initialising the accumulator of the ``MACCS`` instruction to
0.5 rather than 0. For example, if afterwards the middle 32 bits of two
32-bit words are to be selected, one would set the initial accumulator
low word to 0x8000 to implement normal rounding.

Saturation
..........

Each time that 32 bits are selected from a 64 bit multiplication, an
overflow may occur. This means that the high word should be checked for
overflow.

Saturation can be implemented efficiently by checking whether sign
extension is a no-op::

  sext(x,24) == x

If not, then the value x exceeds 24 bits signed. For unsigned number,
``zext`` is used.

Example code sequence
.....................

A simple example with some values is::

  int h, l;
  int a = 0x0010000; // 1.0 in 16.16 format
  int b = 0x0004000; // 0.25 in 16.16 format
  int c = 0x0000100; // 1.0 in 24.8 format
  a = a + b;         // a is still in 16.16 format
  a = a >> 8;        // a is in 24.8 format
  a = a - c;         // a is in 24.8 format
  {h,l} = maccs(0, 0, a, b);   // {h,l} is in 40.24 format, ie, l is
                               // in 8.24 and h is in 40.-8
  if (sext(h, 8) == 8) {
    a = h << 24 | l >> 8; // this is in 16.16 format once again.
  } else {
    if (h > 0) {
      a = 0x7fffffff;
    } else {
      a = 0x80000000;
    }
  }

A more realistic example of a FIR filter is::

  fir(int inp[16], int filter[16]) { // 8.24 and 8.24  |filter[x]| < 1
    h = 0;
    l = 0x800000;
    for(int i = 0; i < 16; i++) {
      {h,l} = maccs(h, l, inp[i], filter[i]);
    }
    if (sext(h, 8) == 8) {
      return h << 8 | l >> 24;
    } else {
      if (h > 0) {
        return = 0x7fffffff;
      } else {
        return = 0x80000000;
      }
    }
  }

This example performs 16 MAC operations followed by a single saturation
test. Note that the MAC operations cannot overflow since there is 7 bits of
headroom in the filter-array.

Multi word arithmetic
---------------------

Longer words (64, 96, or more bits) can be represented by using the LADD,
LMUL, LSUB and LDIV instructions.

The representation can either be signed magnitude, or two's complement.
Signed magnitude is easier for multiplications and divisions, two's
complement is easier for add and subtract.

Assuming unsigned arithmetic (and leaving the signed case to the reader),
the code for an addition is::

  LADD c, f, a, b, 0
  LADD c, g, d, e, c

An LMUL comprises 4 LMUL instructions
