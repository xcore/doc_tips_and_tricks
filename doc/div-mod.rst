Division and modulo
===================

The division instruction on the XS1 shares a divider between all threads,
and takes a number of thread cycles (32) to complete. Division is hence
slower than any other arithmetic instruction; and when multiple threads
perform divisions at the same time, they will slow each other down; a
division may take 32 thread cycles to complete if a thread is unlucky.

Sometimes divisions can be avoided; using well known methods:

Use a shift operation
    A right shift of *n* bits is
    equivalent to unsigned division by *2^n*. For negative numbers, one has
    to be careful that a right shift rounds towards minus infinity.

Multiply by the inverse
    Sometimes the inverse is easily
    calculated, for example when dividing by a constant. In this case, one
    can, at compile time, compute the inverse (*1/n*) and then at run time
    multiply by this number. For an integer division, the inverse is always
    less than one, hence the number to store is *2^32/n* which is then
    multiplied using one of the long multiply instructions (``LMUL``, ``MACCS``). 
    This will compute the result of the division in the most significant 32
    bits, although rounding may not be precise.

See Hacker's delight [warrenjr]_ for a detailed discussion on this subject

.. [warrenjr] TBC
