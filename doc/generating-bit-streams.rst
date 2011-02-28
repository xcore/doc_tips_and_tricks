\section{Generating bit streams}

The simplest method to generate a bit stream is to use a port, and to
output successive values to that port. Eg:

\begin{lstlisting}
p <: 0;
p <: 1;
p <: 0;
p <: 1;
p <: 1;
\end{lstlisting}

This code will generate a sequence \lstinline$01011$ on port \lstinline$p$. If the
bits have to be outputted at a precise time, then the real time clock or a
clocked port can be used to achieve this.

An efficient method to output multiple synchronised output streams is to
make sure that all ports are clocked synchronously, by buffering ports, and
by ensuring that all buffers are always kept full. All these methods are
detailed in the XC programming manual~\cite{xc-en-ebook}.

Alternatively, ports can be clocked of one another. That is, one output
port is clocked of a divided reference clock, and this port is then used as
a clock for one or more other ports. As an example we show part of a 
JTAG implementation.

There are four ports, and two clocks in this example. The four ports drive the
TCK, TDI, and TMS signals, and sample the TDO signal. One of the clocks is
used to clock the TCK pin, the other clock is used to clock the TMS, TDI,
and TDO pins:

\begin{lstlisting}
buffered out port:32 jtag_pin_TCK  = XS1_PORT_1D;
buffered out port:32 jtag_pin_TDI  = XS1_PORT_1A;
buffered in port:32 jtag_pin_TDO  = XS1_PORT_1B;
buffered out port:4 jtag_pin_TMS  = XS1_PORT_1C;

clock tck_clk = XS1_CLKBLK_1;
clock jtag_clk = XS1_CLKBLK_2;
\end{lstlisting}

The initialisation function sets up the clock-blocks, ports, and clock
sources as follows:
\begin{lstlisting}
init() {
    configure_clock_rate(tck_clk, 100, 10);
    configure_out_port(jtag_pin_TCK, tck_clk, 0xffffffff);

    configure_clock_src(jtag_clk, jtag_pin_TCK);
    configure_out_port(jtag_pin_TDI, jtag_clk, 0);
    configure_in_port(jtag_pin_TDO, jtag_clk);
    configure_out_port(jtag_pin_TMS, jtag_clk, 0);
    start_clock(tck_clk);
    start_clock(jtag_clk);
}
\end{lstlisting}
\lstinline+tck_clk+ is set to tick at 10 Mhz, the TCK pin is set to be
clocked of that 10 Mhz clock and initialised to all ones (a high value),
the \lstinline+jtag_clk+ is set to be clocked of the TCK pin, and the other
three ports are clocked of the \lstinline+jtag_clk+, initialising the
output pins with 0. The clocks are then started.

After all the setup, data can now be input and output to the TDO, TDI, and
TMS pins. The trick is to always first place the data on the output port,
and then generate a train of clock pulses on TCK. Note that the program will
continue while the clock pulses are being generated, so there are places
where the program has to wait for all clock pulses being generated.

Initially, the protocol requires us to assert TMS for one clock tick, and
then keep it low for two clock ticks. That is achieved by the following
sequence:
\begin{lstlisting}
    jtag_pin_TMS <: 0b0001;
    jtag_pin_TCK:6 <: 0b101010;      // 3 Clock pulses
    sync(jtag_pin_TCK);
\end{lstlisting}
The data \lstinline$0001$ is placed int he TMS port, and because
\lstinline+jtag_pin_TCK+ is initially high, one TMS bit will be clocked out
on every zero bit of TCK. Three bits will be clocked out in total. The call to
\lstinline$sync$ causes the program to pause until all 6 bits have been
shifted out on TCK, and three bits to have been shifted out of TMS as a result.

Second, the protocol requires us to place data on TDI, clock this data out,
and input data on TDO:
\begin{lstlisting}
    jtag_pin_TDI <: in0;
    clearbuf(jtag_pin_TDO);
    jtag_pin_TCK <: 0xAAAAAAAA;  // 16 Clock pulses
    jtag_pin_TCK <: 0xAAAAAAAA;  // 16 Clock pulses
    jtag_pin_TDO :> out1;
\end{lstlisting}
The first line places 32 bits of data from the variable \lstinline$in0$
into the TDI port; preparing it for transmission. The second line empties
the input buffers of the TDO port, throwing away any data that was clocked
in previously. The third and fourth line generate a total of 32 clock
pulses on the TCK, clocking out all data on TDI, and clocking in 32 bits on
TDO. The last line inputs the data from TDO into the variable
\lstinline$out0$. This statement will block until all 32 bits are present,
and will hence wait for all clocks to be generated.

Using this method also gives flexibility to, for example, generate clocks
that are non symmetrical.
