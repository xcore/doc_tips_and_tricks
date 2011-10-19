Realigning a data stream
========================

In some applications one would like to write a stream of data into memory, but the
destination location is not word aligned in memory. For example, a program
may be reading words from a
32-bit buffered port, and attempting to store these words in a packet
buffer that starts at address 0x13001.

Using MACCU instructions
------------------------

Rather than resorting to short or byte stores, the MACCU instruction can be
used to realign the data in a single clock cycle. The MACCU instruction
computes::

  h:l <- h:l + x * y

In other words::

  h <- h + (l + x * y) / 2^32
  l <- (l + x 8 y) mod 2^32 

We will use *y* as a constant that denotes over how many bytes the data
should be realigned. Assuming that we want to shift by *n* bytes, where *n*
is 0, 1, 2, or 3, we set *y* to 0x1, 0x100, 0x10000, or 0x1000000.
*x* is the word that is input, which contains the most
recently received byte (that should go at the highest location in memory)
in it most significant location, and the oldest data in its least significant
location.

Multiplying *x* by *y* into a 64 bit value will split the word into two
words: the least significant 32 bits of the answer contain the the *4-n*
oldest bytes of data: all 4 bytes for *n* equals 0, 3 bytes for *n* equals
1, and so on. The highest 32 bits of the answer contain the *n* more recent
bytes. The trick is to keep those bytes for the next store, and add those in
with the *4-n* bytes of the next iteration. Conveniently, the MACCU
instruction performs that addition.

In other words, we perform the following operations in a loop::

  x <- input
  h <- 0
  l <- l + (x * y) mod 2^32 
  h <- h + (x * y) / 2^32
  mem[] <- l
  l <- h

The last operation can be removed by unrolling the loop once and renaming
the registers. An XC program that reads words from an input channel/port
and outputs realigned words to an output channel/port is shown below::

 unsigned y = 0x100;
 unsigned h, l = 0, x;
 while(...) {
    h = 0;
    i :> x;
    {h,l} = mac(h,l,x,y);
    o <: l;
    l = 0;
    i :> x;
    {l,h} = mac(l,h,x,y);
    o <: h;
 }

Which realigns a byte stream by one byte. The variable *y* can be set to
any other value with a single '1' bit to achieve different realignments.

Conversely, a MACCU instruction can also be used to pack 24 bit values into 32 bit
values - four MACCU instructions with values 1, 0x1000000, 0x1000, and 0x100
in succession will pack 4 24-bit values into 3 32-bit values.

Realignment using a channel
---------------------------

A channel can also be used to realign data. Data can be output to a channel
in words, and input in words. If, on purpose, a single token is output
prior to a series of word outputs, then each input will input one token
from the last word, and three tokens from the current word.

Since words are transmitted most significant byte first, the byte-reverse
function should be called prior to outputting a word, and after inputting
the word. As an example, the following two functions will realign the data
by one byte::

 #include <xclib.h>

 void sender(streaming chanend x, int a[100]) {
    char c = 0;
    x <: c;
    for(int i = 0; i < 100; i++) {
        x <: byterev(a[i]);
    }
 }

 void receiver(streaming chanend x, int a[100]) {
    for(int i = 0; i < 100; i++) {
        x :> byterev(a[i]);
    }
    x :> char _;
 }

This method is particularly useful on the edge of two processes, where
data would be communicated to another thread anyway. For example, a data
packet may have been received over ethernet and is transmitted to a second
thread for processing.



.. [warrenjr] Henry S Warren, *Hacker's Delight*, ISBN 0201914654

.. [xc-en-ebook] Douglas Watt, *Programming XC on XMOS Devices*, http://www.xmos.com/published/xc_en
