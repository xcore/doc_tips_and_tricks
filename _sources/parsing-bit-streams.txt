Parsing bit streams
...................

Many I/O interfaces require a bit-stream to be parsed. A simple parser
maintains a state, and on every input a state transition is made::

  while(...) {
    p :> x;
    state = newstate[state][x];
  }

This method works fine, under two assumptions:

1. There is enough time to perform the table lookup.
2. There is enough memory to store the table.

The latter can be a problem if the table is not very dense. For example, if
``p`` is an 8-bit port (or an 8-bit buffered 1-bit port), it will
result in values between 0 and 255, but only one or two of these values may
be legal in any one state. In this case, a large part of the table will be
empty, or filled with ``ERROR'' states.

There are two other methods to parse a bit stream that avoid the above two
problems; a faster method that encodes the state in the code space, and a
memory efficient method that uses a hash table.

Encoding the state in code space
================================

In order to encode the state machine in the code space, a {\em label} is used to denote each state;
an input to obtain data, and a conditional (or computed) branch to perform
a state change. For example, the following code has four states, encoding
the last two bits of data that have been input on a one bit port::

 S00:
    in    r1, res[r0]
    bf    r1, S00
 S01:
    in    r1, res[r0]
    bf    r1, S10
 S11:
    in    r1, res[r0]
    bt    r1, S11
 S10:
    in    r1, res[r0]
    bt    r1, S01
    bu    S00

The longest trail of instructions between two subsequent inputs is three,
hence this system can parse one bit every three thread cycles. Extra
instructions can be added to the code to do something useful on 
state transactions.

More bits can be parsed at any one time by using a buffered port, for example a
4-bit buffered port that will result in a 4-bit value, where a ``bru``
instruction can be used to jump based on that value, and ``bl`` instructions to
jump to a new state (note that a ``bl`` instruction can jump up to
1024 instructions either way). When values are input from a serialising
port, the least significant bit is the oldest bit, and the most significant
bit input is the most recent bit. Hence, if on a 4-bit port the value
``0010`` (2) appears, then that means that the port clocked in a
'0', a '1', a '0', and a '0'. In the state machine we reflect this by
jumping to a state ``S0100``::

 S:
    IN       r1, r0
    BRU      r1
    BLRF_u10 S0000
    BLRF_u10 S1000 // Input was '1' followed by three times a '0'
    BLRF_u10 S0100 // Input was '0' followed by a '1' and two '0'
    BLRF_u10 S1100 // ...
    ...
    BLRF_u10 S1111

 ...

 S0100:
    IN       r1, r0
    BRU      r1
    BLRF_u10 S01000000
    BLRF_u10 S01000001
    BLRF_u10 S01000010
    BLRF_u10 S01000011
    ...
    BLRF_u10 S01001111

Obviously, extra instructions need to be added to perform operations, and
the state space needs to be pruned to avoid unreachable states. For
example, one may always expect at least three equal bits in a row, eg
patterns such as ``00100'' are impossible. In this case many of the above
states are illegal and can be covered by a single ERROR state.

Note that the BRU instruction jumps over $n$ 16-bit instructions, and that all
entries in the jumptable should hence be short instructions. Hence they
have been specified as being \lstinline+BLRF_u10+ instructions.

Encoding the state transitions in a hash table
==============================================

The above strategies work fine when small numbers of bits are input at a
time. When large numbers of bits are input that contain only few legal
sequences, these sequences can be stored in a hash table, and hash function
used to perform the state transitions. For example, if a low frequency
signal is sampled at a high rate, and the data is buffered into a 32-bit
value, the only legal values expected are::

  00000000000000000000000000000000
  00000000000000000000000000000001
  00000000000000000000000000000011
  00000000000000000000000000000111
  ...
  01111111111111111111111111111111
  11111111111111111111111111111111
  11111111111111111111111111111110
  11111111111111111111111111111100
  ...
  10000000000000000000000000000000

A hashtable can be built containing those values (see
Section~\ref{section:hash}), this hashtable can contain state values and
encode operations to be performed on state transitions::

  while(1) {
    p :> x;
    hash = hashValue(x);
    state = newState(state, hash)
    // Operations based on state.
  }

Given that only 64 legal values need to be encoded, a polynomial with 6 or
7 bits will probably do the trick, and all polynomials of 6 and 7 bits can
be searched ones in order to create an optimal hash.

Parsing an aligned bit stream by sampling
=========================================

If a bit stream has a known frequency relative to the XCore (give or take a
few percent), then the stream can be parsed by oversampling the data on a
port by a factor $n$, waiting for the start-bit, parse the *n/2* th bit, and
then every $n$th bit until the end of the packet.

For example, suppose that we expect a stream of bits at 12.288 Mhz, then we
can oversample at 100 Mhz (oversampled by a factor 8.13). Wait for the
start bit, and then sample bits 4, 12, 20, 28, 37, 45, 53, 61, etc.

In order to sample those bits, the port is set to buffer 32 bits, and on
the first word the bits are masked out using a mask ``0x08080808``.
In the second word, the mask used is ``0x04040404``, etc. Each mask
leaves four recovered bits in four places in the word, and these can be
recovered by applying a CRC with a polynomial of +0xf+, which
implements a perfect hash onto the last four bits, and a lookup table with
16 elements to recover the 16 possible sampled values::

 p when pinsneq(0) :> int _;        // align first bit
 p :> word;                         // read first word
 fourBits = (word << 4) & 0x80808080;
 crc32(fourBits, 0xf, 0xf);         // compress bits
 data = lookupCrcF[fourBits];       // recover data
 p :> word;                         // read second word
 fourBits = (word << 5) & 0x80808080;
 crc32(fourBits, 0xf, 0xf);
 data = data << 4 | lookupCrcF[fourBits];

Note that rather than using different masks, the same mask is reused on
each inputted word, and the input data is shifted. This means that the four
sampled bits are always in the same location (bits 7, 15, 23, and 31), and
the same lookup table can be used on both the first and the second word.
The array to lookup the CRC values should be initialised with the values
``{8,9,12,13,7,6,3,2,10,11,14,15,5,4,1,0}``; the array values
depend on the mask, the polynomial, and the initial value chosen.

Note that the above code requires around five instructions for each word;
leaving plenty of time for other operations, such as NRZ decoding, or
removing stuff bits.

Finding the alignment of a bit stream
=====================================

If instead of re-aligning a bit stream, it is just important to establish
the alignment, then the {\em count leading zeroes} instruction comes in
useful. A combination of an input followed by a ``clz()`` will, in a total of two
thread cycles, return the bit number of the first '1' bit that was
received. If the first one is required, the input data should be
complemented, using ``clz(~x)``. The bit reverse instruction can be
used to count the number of trailing zeroes: ``clz(bitrev(x))``.
