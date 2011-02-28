
\section{Clearing two registers simultaneously}

Two registers can be cleared simultaneously by executing an \lstinline+LSUB+
instruction. 
\begin{lstlisting}
    LSUB d, e, d, d, c
\end{lstlisting}
will clear $d$ and $e$ in a single clock cycle, provided the bottom bit of
$c$ is zero. It will provide all ones in both $d$ and $e$ if $c$ is one. If
any register $c$ is known to contain a word address, the instruction
\begin{lstlisting}
    LSUB d, e, c, c, c
\end{lstlisting}
will clear both $s$ and $e$.

Similarly, LADD can be used to copy oen register and clear another register
simultaneously. 
