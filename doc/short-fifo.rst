Building short FIFOs
===

A channel can be used as a short fifo, to synchronise two, otherwise
asynchronous, processes. To use it as a short fifo, output
single bytes or words to the channel end using the ``outuchar()``,
``outuint()``, ``inuchar()``, and ``inuint()``
primitives.

The ``uchar`` primitives send 8-bit data values through the channel.
The input primitive will block until data is available, and the output
primitive will block until space is available. A channel
can hold at least 8 bytes; there is no guaranteed upperlimit on the number
of bytes it can store.

The ``uint`` primitives send words through the channel.
The input primitive will block until data is available, and the output
primitive will block until space is available. A channel
can hold at least 64 bits (32-bit words) ; there is no guaranteed upperlimit on the number
of words it can store.

A usage model is where two threads should stay loosely coupled, in
that ``B()`` should be no further than two iterations ahead of
``A()``::

 A(chanend x) {             B(chanend x) {
   unsigned char i = 0 ;      unsigned char i = 0;
   outuchar(x, i++);          while(1) {
   outuchar(x, i++);            inuchar(x);
   while (1) {                  // ... do work
     inuchar(x);                outuchar(x, i);
     // ... do work           }
     outuchar(x, i++);      }
   }
 }

Initially, ``A`` puts two tokens in the FIFO to ``B``. This
indicates that ``B`` can complete two rounds of work without having
to synchronise. Every time that ``B`` completes an iteration, it
puts a token in the FIFO to ``A`` indicating that it has completed
it, ``A`` will not start its work until ``B`` has
completed, and will signal its iteration.

When a FIFO is empty, it indicates that the thread on the receiving side of
that thread cannot progress. When a FIFO contains tokens, it means that the
thread at the receiving end can continue. The FIFOs never contain more than
two tokens.
