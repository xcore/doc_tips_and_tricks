Using multiple threads for super linear speedup
...............................................

In programs there are often two functions calling each other where the
calling function is producing data, and the called function is storing the data. 
By using two threads you can more than double the speed of the
code. This is due to each thread having access to a set of registers to
hold data, and because two threads eliminate the overhead caused by function calls.

Code structure
--------------

As an example, we use JPEG encoding where discretised DCT parameters are
stored as a string of bits, and runs of '0' values are run length encoded.
The two functions are doing the encoding and the bit shuffling/storing. The
code is based on source code from \lstinline$libjpeg$ by Thomas G Lane et al.

The program comprises two functions, ``encode`` and
``emit_bits``, ``encode`` makes repeated calls to
``emit_bits``. The trick is that the latter function requires some
persistent state. This state can be stored in one of three places:

* It can be stored in a structure that is passed to
    ``emit_bits`` on every call (an object oriented way of programming)

* It can be stored in a structure that is a persistent variable inside
    ``emit_bits``  (traditional procedural programming style)

* It can be stored in a thread that runs ``emit_bits``
    (a concurrent programming style)

The three programs are shown at the end

Timings
-------

The execution times are as follows (measured on a 400 Mhz XCore, compiled
with -O2 and array bound checks switched off):

============= ================= ==========
Version       Programming style Time in us 
============= ================= ==========
``encode_oo`` Object Oriented   51.21 
encode_p      Procedural style  51.12 
encode_c      Concurrent style  16.08 
============= ================= ==========

Note that the concurrent version runs more than three times faster, using only
two threads. The extra factor 1.5 speed-up is due to two factors:

1. Foremost, the program has access to twice the number of register
variables. This means that all variables are kept in registers. In
particular, the state used by ``emit_bits`` is kept in registers.

2. Second, Function calls are avoided, avoiding the need to save registers, and
create parameter lists. This can be resolved by inlining functions, but
in addition to a code bloat ``emit_bits`` is called three
  times), it also leads to registers being spilled to the stack.


Code listings for threads
--------------

All three code segments assume the following global definitions::

  struct pers {
      int current;
      int length;
      int ncodes;
      int codes[512];
  };

  int ehufco[256], ehufsi[256];

The program written in an object-oriented, procedural, and concurrent style are listed
on the subsequent three pages. The last page shows the main program::

 void emit_bits_oo(struct pers &state,int code,int length) {
    state.length += length;
    if (state.length > 32) {
        int t;
        state.length -= 32;
        t = state.current << (length - state.length);
        t |= code >> state.length;
        state.codes[state.ncodes] = t;
        state.ncodes++;
        state.current = code;
    } else {
        state.current <<= length;
        state.current |= code;
    }
 }
 void encode_oo(int block[64]) {
    int temp, i, k, temp2, nbits;
    int r = 0;
    struct pers state; state.ncodes = state.length = 0;
    for (k = 0; k < 64; k++) {
        if ((temp = block[k]) == 0) {
            r++;
        } else {
            while (r > 15) {
                emit_bits_oo(state,ehufco[0xF0],ehufsi[0xF0]);
                r -= 16;
            }
            temp2 = temp;
            if (temp < 0) {
                temp = -temp;
                temp2--;
            }
            nbits = 32-clz(temp);
            i = (r << 4) + nbits;
            emit_bits_oo(state, ehufco[i], ehufsi[i]);
            emit_bits_oo(state, (unsigned int) temp2, nbits);
            r = 0;
        }
    }
 }


 void emit_bits_p(int code, int length) {
    static struct pers state;
    state.length += length;
    if (state.length > 32) {
        int t;
        state.length -= 32;
        t = state.current << (length - state.length);
        t |= code >> state.length;
        state.codes[state.ncodes] = t;
        state.ncodes++;
        state.current = code;
    } else {
        state.current <<= length;
        state.current |= code;
    }
 }
 void encode_p(int block[64]) {
    int temp, i, k, temp2, nbits;
    int r = 0;

    for (k = 0; k < 64; k++) {
        if ((temp = block[k]) == 0) {
            r++;
        } else {
            while (r > 15) {
                emit_bits_p(ehufco[0xF0], ehufsi[0xF0]);
                r -= 16;
            }
            temp2 = temp;
            if (temp < 0) {
                temp = -temp;
                temp2--;
            }
            nbits = 32-clz(temp);
            i = (r << 4) + nbits;
            emit_bits_p(ehufco[i], ehufsi[i]);
            emit_bits_p((unsigned int) temp2, nbits);
            r = 0;
        }
    }
 }
 void emit_bits_c(streaming chanend inp) {
  int code, length, state_current;
  int state_length = 0, state_ncodes = 0, state_codes[512];
  while(1) {
    inp :> code;   inp :> length;
    state_length += length;
    if (state_length > 32) {
        int t;
        state_length -= 32;
        t = state_current << (length - state_length);
        t |= code >> state_length;
        state_codes[state_ncodes] = t;
        state_ncodes++;
        state_current = code;
    } else {
        state_current <<= length;
        state_current |= code;
    }
  }
 }
 void encode_c(streaming chanend outp, int block[64]) {
    int temp, i, k, temp2, nbits;
    int r = 0;

    for (k = 0; k < 64; k++) {
        if ((temp = block[k]) == 0) {
            r++;
        } else {
            while (r > 15) {
                outp <: ehufco[0xF0]; outp <: ehufsi[0xF0];
                r -= 16;
            }
            temp2 = temp;
            if (temp < 0) {
                temp = -temp;
                temp2--;
            }
            nbits = 32-clz(temp);
            i = (r << 4) + nbits;
            outp <: ehufco[i]; outp <: ehufsi[i];
            outp <: (unsigned int) temp2; outp <: nbits;
            r = 0;
        }
    }
 }
