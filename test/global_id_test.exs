defmodule GlobalIdTest do
  use ExUnit.Case
  doctest GlobalId

  @ids_per_node 1_000_000
  @nodes 3
  @total_ids_count @ids_per_node * @nodes

  test "should create unique global ids" do
    total_ids =
      1..@nodes
      |> Enum.reduce([], fn _, nodes -> [gen_node_id(nodes) | nodes] end)
      |> Enum.map(&Task.async(fn -> generate_ids(&1, @ids_per_node) end))
      |> Enum.map(&Task.await(&1, 60_000))
      |> List.flatten()

    assert @total_ids_count == length(total_ids)
    assert @total_ids_count == length(Enum.uniq(total_ids))
  end

  defp gen_node_id(node_ids) do
    id = :random.uniform(1024) - 1

    if id in node_ids,
      do: gen_node_id(node_ids),
      else: id
  end

  defp generate_ids(node_id, amount) do
    Process.put(:node_id, node_id)

    for _ <- 1..amount, reduce: [] do
      [] ->
        [GlobalId.get_id(0)]

      [last_id | _] = ids ->
        new_id = GlobalId.get_id(last_id)
        assert last_id < new_id
        [new_id | ids]
    end
  end
end
