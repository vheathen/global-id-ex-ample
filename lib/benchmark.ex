defmodule GlobalId.Benchmark do
  import GlobalId

  require Logger

  @doc """
  Single process benchmark
  """
  @spec benchmark(non_neg_integer(), non_neg_integer()) :: :ok
  def benchmark(ids_amount \\ 1_000_000, node_id \\ nil)

  def benchmark(ids_amount, nil), do: benchmark(ids_amount, :rand.uniform(1024) - 1)

  def benchmark(ids_amount, node_id) do
    start = System.monotonic_time()

    Logger.debug("Node #{node_id} started")

    Process.put(:node_id, node_id)

    Enum.reduce(1..ids_amount, 0, fn _, last_id -> get_id(last_id) end)

    finish = System.monotonic_time()
    ms = System.convert_time_unit(finish - start, :native, :millisecond)
    per_second = round(ids_amount / (ms / 1000))

    Logger.debug("Node #{node_id}: #{ids_amount} ids generated in #{ms} ms, or #{per_second}/sec")

    :ok
  end

  @doc """
  Multi-process benchmark
  """
  #
  ## Real world example, Intel Xeon E5-2665 v1:
  # iex(1)> B.benchmark_multi(2, 10_000_000)
  # 13:06:22.436 [debug] Benchmark started on 2 nodes with target as 10000000 ids per node
  # 13:06:22.440 [debug] Node 740 started
  # 13:06:22.440 [debug] Node 454 started
  # 13:06:28.219 [debug] Node 454: 10000000 ids generated in 5778 ms, or 1730703/sec
  # 13:06:28.228 [debug] Node 740: 10000000 ids generated in 5787 ms, or 1728011/sec
  # 13:06:28.228 [debug] Total: 20000000 ids generated in 5791 ms, or 3453635/sec
  # :ok
  #
  @spec benchmark_multi(non_neg_integer(), non_neg_integer()) :: :ok
  def benchmark_multi(nodes \\ 3, ids_per_node \\ 10_000_000) do
    start = System.monotonic_time()

    Logger.debug(
      "Benchmark started on #{nodes} nodes with target as #{ids_per_node} ids per node"
    )

    1..nodes
    |> Enum.reduce([], fn _, nodes -> [gen_node_id(nodes) | nodes] end)
    |> Enum.map(&Task.async(fn -> benchmark(ids_per_node, &1) end))
    |> Enum.map(&Task.await(&1, 60_000))

    finish = System.monotonic_time()
    ms = System.convert_time_unit(finish - start, :native, :millisecond)
    per_second = round(ids_per_node * nodes / (ms / 1000))

    Logger.debug("Total: #{ids_per_node * nodes} ids generated in #{ms} ms, or #{per_second}/sec")

    :ok
  end

  defp gen_node_id(node_ids) do
    id = :rand.uniform(1024) - 1

    if id in node_ids,
      do: gen_node_id(node_ids),
      else: id
  end
end
