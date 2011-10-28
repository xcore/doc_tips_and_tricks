Multiplying a double word with a word
=====================================

If you want to compute ``c = a * b`` where ``b`` and ``c`` are double word numbers
and ``a`` is a single word number, then you can do that as follows::

  unsigned a;
  unsigned hb, lb;
  unsigned hc, lc;

  {hc,lc} = macs(lb, a, hb*a, 0)

Where ``{hb,lb}`` are the high and the low word of ``b``, and 
``{hc,lc}`` are the high and the low word of ``c``.

