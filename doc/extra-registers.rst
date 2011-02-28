

\section{Using extra registers}

The XCore has 12 general purpose registers. If this is not sufficient, then
it may be possible to use the $cp$, $dp$, and $sp$ registers to store a
memory address. Although they cannot be used in all instructions, they can
be used to efficiently store and retrieve values from memory.

For example, $dp$ can be set to point to the base of an array, and the
$LDWDP$ and $STWDP$ instructions can be used to access values in that
array. Note that the index has to be constant. $cp$ can be used too, and
has the added advantage of allowing a wide range to be indexed with a short
instruction. However, there is no instruction to store data relative to
$cp$ (as it is meant to point to the constant pool).

The $dp$, and $sp$ pointers can be advanced using the $EXTSP$ instruction.
Note that each thread has its own $dp$, $cp$, and $sp$ register, so a
thread can safely reappropriate any of those.
