Computing a logarithm or sqrt
=============================

The XS1 has an instruction to count the number of leading zeroes of a bit
pattern, \lstinline+clz()+. This function can be used to efficiently
estimate the logarithm of a number. Assuming $x \not = 0$, then::

  \lfloor \log_2 x \rfloor = bpw - 1 - clz(x)

This logarithm can be used as a first estimate for a square root, since::

  \sqrt{x} = x^{\frac{1}{2}} = 2^{\frac{\log_2 x}{2}}

This is all implemented using shift operations::

  sqrtx = 1 << ((31-clz(x))>>1);

This estimate can be improved iteratively using the Newton-Raphson algorithm. Since the
first bit is of the square root is already correct, only 3 or 4 iterations
will produce an accurate square root::

  int sqrt(int x) {
    int d, root = 1 << ((31-clz(x))>>1);
    do {
      d = (root*root - x)/(2*root);
      root = root - d;
    } while (d > 1 || d < -1);
    return root;
  }

See Hacker's delight [warrenjr]_ and Paul Hsieh's
website [sqrt-hsieh]_ for an in-depth discussion.

.. [warrenjr]_ TBC

.. [sqrt-hsieh]_ TBC
