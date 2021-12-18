# collatz-metal
A Swift and Metal program that computes the longest Collatz sequence for values 1 to n in parallel.

Doesn't work. Sometimes the maximum sequence length is wrong. So I have a parallelism bug after all.

Also, the biggest performance bottleneck right now is the <code>atomic_fetch_max_explicit</code> function that I'm using (from Metal).
Maybe that's the fastest solution, or maybe there's something faster I can do.
