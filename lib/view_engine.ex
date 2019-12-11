defmodule ViewEngine do
  use GenServer

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: :view_engine)
  end

  def init([]) do
    {:ok, %{}}
  end
  def init(state) do
    {:ok, state}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  def handle_cast({:set, key, value}, state) do
    {:noreply, Map.put_new(state, key, value)}
  end

  # Client
  def get(key), do: GenServer.call(:view_engine, {:get, key})
  def set(key, value), do: GenServer.cast(:view_engine, {:set, key, value})

end
