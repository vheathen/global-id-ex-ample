defmodule GlobalId do
  @moduledoc """
  GlobalId module contains an implementation of a guaranteed globally unique id system.

  Current implementation is able to generate up to 2_048_000 ids per second per process
  and should guarantee id uniqueness until 2248-09-26 15:10:22.208 UTC (43 bits timestamp).
  Varying timestamp/counter bit length it is possible to change maximum generation performance.
  """

  @node_id :random.uniform(1024) - 1
  @endless_retries true

  @timestamp_length 43
  @counter_length 11
  @counter_max round(:math.pow(2, @counter_length)) - 1

  @doc """
  Please implement the following function.
  64 bit non negative integer output
  """
  @spec get_id(non_neg_integer) :: non_neg_integer
  def get_id(last_id), do: do_get_id(<<last_id::64>>, timestamp_bt())

  #
  # You are given the following helper functions
  # Presume they are implemented - there is no need to implement them.
  #

  @doc """
  Returns your node id as an integer.
  It will be greater than or equal to 0 and less than or equal to 1023.
  It is guaranteed to be globally unique.
  """
  @spec node_id() :: non_neg_integer
  def node_id, do: Process.get(:node_id, @node_id)

  @doc """
  Returns timestamp since the epoch in milliseconds.
  """
  @spec timestamp() :: non_neg_integer
  def timestamp, do: System.system_time(:millisecond)

  #
  # Private API
  #

  #
  # If we request for a new id within the same time slot:
  #
  # We can have max 2^11 = 2048 ids per millisecond so if we
  # got counter == 2047 (0..2047) then we need to sleep till the
  # next timeslot or retry immediately
  #
  defp do_get_id(
         <<current_timestamp::@timestamp_length, @counter_max::@counter_length, _node_id::10>> =
           last_id,
         <<current_timestamp::@timestamp_length>>
       ) do
    unless @endless_retries, do: Process.sleep(1)
    do_get_id(last_id, timestamp_bt())
  end

  #
  # Just increment counter within the current timeslot and return a new id
  #
  defp do_get_id(
         <<current_timestamp::@timestamp_length, counter::@counter_length, _node_id::10>>,
         <<current_timestamp::@timestamp_length>>
       ),
       do: return_id(current_timestamp, counter + 1)

  #
  # This shouldn't happens but if we've got an id from future (for example,
  # because of the timestamp generator source time drift) we need to wait till
  # that future to ensure the next ids are unique.
  #
  # Here also can be different strategies: for example, not waiting but retries in case time
  # fluctuation was incidental and temporary.
  #
  defp do_get_id(
         <<future_timestamp::@timestamp_length, _counter::@counter_length, _node_id::10>> =
           last_id,
         <<current_timestamp::@timestamp_length>>
       )
       when future_timestamp > current_timestamp do
    Process.sleep(future_timestamp - current_timestamp)
    do_get_id(last_id, timestamp_bt())
  end

  #
  # And if the last id timestamp from the past we can reset counter to zero
  #
  defp do_get_id(
         <<past_timestamp::@timestamp_length, _counter::@counter_length, _node_id::10>>,
         <<current_timestamp::@timestamp_length>>
       )
       when past_timestamp < current_timestamp,
       do: return_id(current_timestamp, 0)

  defp return_id(timestamp, counter) do
    return_id(<<timestamp::@timestamp_length, counter::@counter_length, node_id()::10>>)
  end

  #
  # Let's make an intereger from a bitstring and return it
  #
  defp return_id(<<result::64>>), do: result

  defp timestamp_bt, do: <<timestamp()::@timestamp_length>>
end
