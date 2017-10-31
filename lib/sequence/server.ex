defmodule Sequence.Server do
  use GenServer
  require Logger

  @vsn "2"
  defmodule State do
    defstruct current_number: 0, stash_pid: nil, delta: 1
  end

  def code_change("1", state, _extra) do
    Logger.info "Changing code from 1 to 2"
    Logger.info inspect(state)
    Sequence.Stash.save_value(state.stash_pid, [state.current_number, state.delta])
    {:ok, state}
  end

  ####
  # External API

  def start_link(stash_pid) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, stash_pid, name: __MODULE__)
  end

  def next_number do
    with number = GenServer.call(__MODULE__, :next_number),
    do: "The next number is #{number}"
  end

  def increment_number(delta) do
    GenServer.cast __MODULE__, {:increment_number, delta}
  end

  ####
  # GenServer implementation

  def init(stash_pid) do
    [current_number, delta] = Sequence.Stash.get_value(stash_pid)
    {:ok, %State{current_number: current_number, stash_pid: stash_pid, delta: delta}}
  end

  def handle_call(:next_number, _from, state) do
    {:reply, state.current_number, %{state 
    | current_number: state.current_number + state.delta}}
  end

  def handle_cast({:increment_number, delta}, state) do
    {:noreply, %{state | current_number: state.current_number + delta, delta: delta}}
  end

  def terminate(_reason, state) do
    Sequence.Stash.save_value(state.stash_pid, [state.current_number, state.delta])
  end

  def format_status(_reason, [_pdict, state]) do
    [data: [{'State', "My current status is '#{inspect(state)}', and I'm happy"}]]
  end

end