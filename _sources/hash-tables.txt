Hash tables
===========

A hash table is a well understood data structure to store data. Typically,
a hash table stores pairs *(key,value)*, and the objective is to use little
memory to store those but with a fast access mechanism. Hash tables are
described in detail by Knuth [knuth3]_.

A good hash function is critical to making efficient hash tables. Good hash
functions can be expensive to compute, but functions that are cheap to
compute may have poor hashing qualities.

The XS1 instruction set offers a CRC instruction that can compute a reasonable
hash in a single clock cycle. The CRC instruction computes the modulo when
dividing by a binary polynomial. This is known to have good hashing
properties if the right polynomial is chosen.

The way to use the CRC instruction is as follows (assuming that there is an
array of words x[] over which we want to create a hash)::

  hash = ~0;
  for(int i = 0; i < n; i++) {
    crc32(hash, x[i], polynomial);
  }

For the special case where the key is only one word, this for-loop reverts
to one thread cycle to initialise the variable ``hash``, and call
to ``crc32()`` which is also executed in a single thread cycle.

The polynomial should be chosen as follows:

* The length of the polynomial determines the size of the hashtable
  addressed. For a polynomial of length *n*, the hash table will have
  *2^n* entries. A polynomial of length *n* will have *32-n* zero bits as
  its most significant bits, then a *1* bit, and then zero and 1 bits.

* The polynomial should have good spreading properties. We refer to
  Knuth for details [knuth3]_. As a rule of thumb, primitive
  polynomials [wikipedia-primitive-polynomial]_ are good.

If all values that are to be stored are known at compile time, then the
polynomial can be chosen to minimise the hashtable by performing an
exhaustive search over all possible polynomials.

.. [knuth3] Donald Knuth, *The Art of Computer Programming: Sorting and Searching*, ISBN 0201896850.

.. [wikipedia-primitive-polynomial] *Primitive Polynomial pages on Wikipedia* http://en.wikipedia.org/wiki/Primitive_polynomial
