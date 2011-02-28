\section{Hash tables}
\label{section:hash}

A hash table is a well understood data structure to store data. Typically,
a hash table stores pairs {\em (key,value)}, and the objective is to use little
memory to store those but with a fast access mechanism. Hash tables are
described in detail by Knuth~\cite{knuth3}.

A good hash function is critical to making efficient hash tables. Good hash
functions can be expensive to compute, but functions that are cheap to
compute may have poor hashing qualities.

The XS1 instruction set offers a CRC instruction that can compute a reasonable
hash in a single clock cycle. The CRC instruction computes the modulo when
dividing by a binary polynomial. This is known to have good hashing
properties if the right polynomial is chosen.

The way to use the CRC instruction is as follows (assuming that there is an
array of words x[] over which we want to create a hash):
\begin{lstlisting}
  hash = ~0;
  for(int i = 0; i < n; i++) {
    crc32(hash, x[i], polynomial);
  }
\end{lstlisting}
For the special case where the key is only one word, this for-loop reverts
to one thread cycle to initialise the variable \lstinline$hash$, and call
to crc32() which is also executed in a single thread cycle.

The polynomial should be chosen as follows:
\begin{itemize}
  \item The length of the polynomial determines the size of the hashtable
    addressed. For a polynomial of length $n$, the hash table will have
    $2^n$ entries. A polynomial of length $n$ will have $32-n$ zero bits as
    its most significant bits, then a $1$ bit, and then zero and 1 bits.
  \item The polynomial should have good spreading properties. We refer to
    Knuth for details~\cite{knuth3}. As a rule of thumb, primitive
    polynomials~\cite{wikipedia-primitive-polynomial} are good.
\end{itemize}
If all values that are to be stored are known at compile time, then the
polynomial can be chosen to minimise the hashtable by performing an
exhaustive search over all possible polynomials.
