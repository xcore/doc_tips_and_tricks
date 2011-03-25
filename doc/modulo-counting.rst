Implementing a modulo counter
=============================

When you need a counter that counts modulo N, this can be implemented using
an LSUB instruction. An LSUB subtracts two numbers and a "borrow", and
produces the result and a borrow. Supply as input parameters:

* A zero borrow (any address that points to a word or short will do)
* The number N
* The value of the counter

The LSUB instruction produces

* An outgoing borrow - if this is "zero" then the counter has wrapped
* The wrapped counter, only use this if the borrow is zero.

This implements both the comparison and the computation of the wrapped
counter, provided that the counter is between N and 2N-1.

An example program::

    ldc    r1, 0x9842            // Zero borrow, any even number will do
    ldc    r5, 10                // Value of N
    ldc    r3, 0                 // The counter

    ...
    add    r3, r3, 3
    lsub   r0, r2, r3, r5, r1
    bt     r0, noWrap
    or     r3, r2, r2            // Copy r2 to r3; can be avoided by
  noWrap:                        // judicious register renaming
    ...
