defmodule MessageQueueExample.Worker do
  @moduledoc """
  Task used to process next messages in the queue if there is one with a delay
  """
  use Task

  def child_spec(name, delay_in_milliseconds, call_on) do
    %{
      id: name,
      start: {__MODULE__, :start_link, [name, delay_in_milliseconds, call_on]}
    }
  end

  @doc """
  Start the worker tied to a name queue and on each message call the call_on function
  with a delay in milliseconds
  """
  def start_link(name, delay_in_milliseconds, call_on) do
    Task.start_link(__MODULE__, :poll, [name, delay_in_milliseconds, call_on])
  end

  # Used to start the loop to fetch a new message from the named queue based on the delay
  def poll(name, delay_in_milliseconds, call_on) do
    receive do
      :shutdown -> nil
    after
      delay_in_milliseconds ->
        process_next_message(name, call_on)
        poll(name, delay_in_milliseconds, call_on)
    end
  end

  # Process the next message from the named queue and do nothing if there isn't one
  def process_next_message(name, call_on) do
    case MessageQueueExample.Queue.next(name) do
      {:ok, message} ->
        call_on.(name, message)

      _ ->
        nil
    end
  end
end
