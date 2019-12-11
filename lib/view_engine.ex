defmodule ViewEngine do
  use GenServer

  def start_link(init_args, opts) do
    GenServer.start_link(__MODULE__, init_args, opts)
  end

  def init([]) do
    {:ok, %{}}
  end
  def init(%{"path" => path} = state) do
    {:ok, state}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  def handle_cast({:set, key, value}, state) do
    {:noreply, Map.put_new(state, key, value)}
  end

  # Client
  def get(name, key), do: GenServer.call(name, {:get, key})
  def set(name, key, value), do: GenServer.cast(name, {:set, key, value})

end
