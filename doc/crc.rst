Computing and Checking CRCs
===========================

Cycling Redundancy Checks (CRCs) are a common form of checking for the
integrity of data on transmission or storage. The XMOS XS1 instruction set
has dedicated instructions for computing and checking CRCs. In this section
we discuss how to use the CRC instructions.

CRC mathematics
---------------

A CRC is defined as the remainder of a division of two polynomials in GF-2.
The simplest way to visualise a CRC is to use a long
division~\cite{wikipedia-CRC}. Put the input string down at the top (first
bt on the left, last bit on the right), then start dividing by performing
an XOR with the polynomial if the first bit is 1, and not performing an XOR
otherwise. The following example divides 110100110 by
1100 using XOR arithmetic (GF-2), resulting in a modulus of 1110::

  110100110 <--- Input
  1100    . <--- XOR with divisor (4 Bits)
   0010   .
   0000   .
    0100  .
    0000  .
     1001 .
     1100 .
      1011.
      1100.
       1110<- remainder

When all bits of input have been shifted in, the result is guaranteed four
bits; these four bits are the CRC.

CRC using digital electronics
-----------------------------

Instead of using the mathematical description, many protocols specify the
CRC as a linear-feedback-shift-register, which is the common implementation
in digitial electronics. In this implementation, the remainder is commonly
shifted from left to right, and the right most bit (the first bit of data
that came in) is XORed in in the bit locations marked by the CRC.

The above example would progress as follows::

  Remainder  r[0..3]                  1011
  XOR r[3] onto r[2] and r[3]:        1000
  Shift right, shifting next data in: 0100
  XOR r[3] onto r[2] and r[3]:        0100
  Shift right, shifting next data in: 0010  
  XOR r[3] onto r[2] and r[3]:        0010
  Shift right, shifting next data in: 1001
  XOR r[3] onto r[2] and r[3]:        1010
  Shift right, shifting next data in: 1101
  XOR r[3] onto r[2] and r[3]:        1110
  Shift right, shifting next data in: 0111

Note that the answer is the same, but that the bits are written down in a
reverse order.

The polynomial
--------------

The CRC above uses the polynomial x^0 + x^1 + x^4; terms 0, 1, and 4 are
used, which can be represented as 11001 (with the left most bit denoting the
presence of x^0), or 10011 (with the rightmost bit denoting the presence of
x^0).

For a polynomial of order N, the term x^N must always be present, and
hence when specifying a polynomial, this bit is not specified. Hence, the
polynomial x^0 + x^1 + x^4 is known as either 1100 or 0011, where the former
is the *reverse* representation, and the latter is the *normal*
representation. For example, the polynomial used for Ethernet is x^32 +
x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 +
x^2 + x^1 + x^0, or (1)0000 0100 1100 0001 0001 1101 1011 0111, which is
0x04C11DB7 in normal representation, or 0xEDB88320 in reverse notation.

When using the XMOS XS1 instructions, you should always specify your
polynomial in reverse order (eg, 0xEDB88320 for Ethernet). THe lenght of
the polynomial is implicit in the polynomial.

Bit ordering
------------

In order to efficiently compute a CRC, the XMOS XS1 processor will fold 8
or 32 bits into the CRC at a time. The CRC8 instruction will fold in 8 bits
(specified with the 'first' bit in bit 0, and the last bit in bit 7), and
folds them in .The CRC32 instruction will fold in 32 bits starting with bit
0, all the way to bit 31.

If the bit ordering of data stored in memory or data coming from your input
stream is different, then the BITREV and BYTEREV instructions can be used
to alter the order. BITREV will swap all bits form left to right. BYTEREV
swaps the byte in a word. A compbination of the two can swap all bits in a
byte. 

The initial value
-----------------

In the examples above, we have started the computation of the remainder
with the first few data bits already in place. Normally, a CRC computation
would start with an initial value, such as '0', and then the CRC
computatation takes place. on the data. The two most common starting
patterns are a remainder of all zeroes, or a remainder of all ones.

When starting with four zeroes on our previous example, the first four
operations will not do anything, until the first four data bits are shifted
in::

  0000110100110 <--- Input
  0000   . <--- XOR with divisor (4 Bits)
   0001  .
   0000  .
    0011 .
    0000 .
     0110.
     0000.
      1101
      etc.

Hence, if the starting value is all zeroes, then we can simply omit this, and
start with the first N bits, where N is the order of the polynomial.
Indeed, any zero bits at the beginning of the data stream do not contribute
to the CRC. This is why other standards specify that the initial value
should be all ones::

  1111110100110 <--- Input
  1100   . <--- XOR with divisor (4 Bits)
   0111  .
   0000  .
    1111 .
    1100 .
     0110.
     0000.
      1101
      1100
      etc.

Note that whether the XOR happens in teh first four steps, is data
*independent*. In the case of the polynomial shown here (1100), the XOR
happens in the first and third step. Hence, the data is XORed with::

  1111ABCD
  1100
   0000
    1100
     0000
  --------- XOR
  0000ABCD

Hence, the first step can be skipped. For all polynomials the first step
will comprise an XOR with some constant value. In the case of the Ethernet
polynomial, the first step happens to be an XOR with all ones, which is
simply inverting the first dataword.
For any start value, the first steps are data independent, and a constant
XOR value can be computed.

The CRC that is transmitted
---------------------------

The final CRC of a polynomial of order N is N bits, and these are either
transmitted plain, or they may have to be inverted.


Computing a CRC over an odd number of bits
------------------------------------------

Many CRCs are computed over a bit-stream which is a whole number of bytes
long. In this case, the CRC32 instruction can be used on all words of data
until there are 0, 1, 2, or 3 bytes left, whereupon a CRC8 instruction is
applied 0, 1, 2, or 3 times.

Tehre are cases where the number of bits is not a multiple of 8; for
example in the case of a CAN packet. In that case the most efficient
solution is to prepend an N-bit packet with ``32-(N mod 32)`` zero bits.
This will align the end of the packet onto a 32-bit boundary, meaning that
CRC32 instructions can be used all the way. The only problem is to realign
each word. This can be done with a MACCU as is shown in a different chapter
of this document.

Note that if the number of bits is not known in advance, then the final
bits will ahve to be folded in one at a time.

XS1 CRC instructions
--------------------

The XMOS XS1 instructions has two instructions to compute a CRC.

* The CRC instruction computes a new remainder, given a polynomial and a
  a current remainder, and 32 input bits.

* The CRC8 instruction computes a new remainder, given a polynomial and a
  a current remainder, and 8 input bits. In addition, it shifts 8 bits outs
  of the data word, enabling multiple CRC8 instructions to be chained to
  fold 16 or 24 bits into the CRC.
