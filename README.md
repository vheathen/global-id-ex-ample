# GlobalId

An example solution for the Shoreline problem described on [Elixir Forum](https://elixirforum.com/t/elixir-engineer-at-shoreline-onsite-and-remote/38638)

Real world example, Intel Xeon E5-2665 v1, 2 vCPU VM:

```(elixir)
iex(1)> GlobalId.Benchmark.benchmark_multi(2, 10_000_000)
13:06:22.436 [debug] Benchmark started on 2 nodes with target as 10000000 ids per node
13:06:22.440 [debug] Node 740 started
13:06:22.440 [debug] Node 454 started
13:06:28.219 [debug] Node 454: 10000000 ids generated in 5778 ms, or 1730703/sec
13:06:28.228 [debug] Node 740: 10000000 ids generated in 5787 ms, or 1728011/sec
13:06:28.228 [debug] Total: 20000000 ids generated in 5791 ms, or 3453635/sec
:ok
```

## Installation

```
git clone https://github.com/vheathen/global-id-ex-ample
cd global-id-ex-ample
mix deps.get
mix compile
iex -S mix
iex(1)> GlobalId.Benchmark.benchmark_multi(2, 10_000_000)
```

