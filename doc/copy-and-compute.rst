Copying a register simultaneous with a computation
==================================================

The ``LMUL`` instruction can at the same time copy a value into a register,
and compute with it. This is useful for sequences such as::

    port :> value @ newTime;
    diff = newTime - oldTime;
    newTime = oldTime;

An ``LMUL`` instruction performs an  *unsigned* multiplication and two
additions, yielding a 64-bit unsigned result value::

   d : e = a * b + c + d

If we choose ``b`` to be a small negative number, then this is results in::

   d : e = a * (2^32 + b) + c + d     // Computation is unsigned
         = a * 2^32 + a * b + c + d

If we force ``a * b + c + d`` to be positive, then ``a`` will be copied
into ``d``, and ``a * b + c + d`` will be calculated into ``e``. We can
force the answer to be positive by loading ``d`` with an appropriate
offset, for example ``0x10000`` for our example (since port timers are
16 bits only). Hence, the above example code can be written as::

    port :> value @ newTime;
    {oldTime,diff} = lmul(-1, newTime, oldTime, 0x10000);

Will perform the copy and subtraction simultaneously.
