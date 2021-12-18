# collatz-metal
A Swift and Metal program that computes the longest Collatz sequence for values 1 to n in parallel.

Works okay. The biggest bottleneck right now is the <code>atomic_fetch_max_explicit</code> function that I'm using (from Metal).
Maybe that's the fastest solution, or maybe there's something faster I can do.

If you have any ideas, please let me know.
