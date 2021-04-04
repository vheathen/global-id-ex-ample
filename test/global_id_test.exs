defmodule GlobalIdTest do
  use ExUnit.Case
  doctest GlobalId

  alias ETS.Set

  @ids_per_node 10_000_000
  @nodes 4
  @total_ids_count @ids_per_node * @nodes

  test "should create unique global ids" do
    {:ok, table} =
      Set.new(
        keypos: 1,
        ordered: true,
        protection: :public,
        write_concurrency: true,
        read_concurrency: true
      )

    1..@nodes
    |> Enum.reduce([], fn _, nodes -> [gen_node_id(nodes) | nodes] end)
    |> Enum.map(&Task.async(fn -> generate_ids(&1, @ids_per_node, table) end))
    |> Enum.map(&Task.await(&1, 1_000_000))

    check_order_and_count(table)
  end

  defp gen_node_id(node_ids) do
    id = :rand.uniform(1024) - 1

    if id in node_ids,
      do: gen_node_id(node_ids),
      else: id
  end

  defp generate_ids(node_id, amount, table) do
    Process.put(:node_id, node_id)

    for _ <- 1..amount, reduce: GlobalId.get_id(0) do
      last_id ->
        new_id = GlobalId.get_id(last_id)
        <<timestamp::43, counter::11, node_id::10>> = <<new_id::64>>

        Set.put!(table, {new_id, timestamp, counter, node_id})

        new_id
    end
  end

  defp check_two_id_tuples(t1, t2) do
    case {t1, t2} do
      # same node, same timestamp
      {{id, timestamp, c, node_id} = tuple, {p_id, timestamp, p_c, node_id}} ->
        assert id > p_id
        assert c > p_c

        tuple

      # same node, different timestamps
      {{id, ts, _c, node_id} = tuple, {p_id, p_ts, _p_c, node_id}} ->
        assert ts > p_ts
        assert id > p_id

        tuple

      # different nodes, same timestamp, same counter
      {{id, ts, c, n_id} = tuple, {p_id, ts, c, p_n_id}} ->
        assert id > p_id
        assert n_id > p_n_id

        tuple

      # different nodes, same timestamp, different counters
      {{id, ts, _c, _n_id} = tuple, {p_id, ts, _p_c, _p_n_id}} ->
        assert id > p_id

        tuple

      # different nodes, different timestamps
      {{id, ts, _c, _n_id} = tuple, {p_id, p_ts, _p_c, _p_n_id}} ->
        assert id > p_id
        assert ts > p_ts

        tuple
    end
  end

  defp check_order_and_count(table) do
    first_key = Set.first!(table)

    {:ok, first_tuple} = Set.fetch(table, first_key)

    check_order_and_count(table, Set.next(table, first_key), first_tuple, 1)
  end

  defp check_order_and_count(table, {:ok, current_key}, t2, counter) do
    assert {:ok, t1} = Set.fetch(table, current_key)
    check_two_id_tuples(t1, t2)

    check_order_and_count(table, Set.next(table, current_key), t1, counter + 1)
  end

  defp check_order_and_count(_table, {:error, _}, _, counter) do
    assert counter == @total_ids_count
  end
end
