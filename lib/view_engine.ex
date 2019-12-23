defmodule ViewEngine do
  use GenServer

  def start_link(init_args, opts) do
    GenServer.start_link(__MODULE__, init_args, opts)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:get, key}, _from, state) do
    template = Map.get(state, key)
    {:reply, template, state}
  end

  def handle_cast({:set, key, value}, state) do
    {:noreply, Map.put(state, key, value)}
  end

  # Template API
  def include(path) do
    path = String.replace(path, ".", "/")
    EEx.eval_file("./views/#{path}.html.eex")
  end

  def extends(path) do
    path = "./views/" <> String.replace(path, ".", "/") <> ".html.eex"
    File.read!(path)
  end

  def section(name) do
    ~s(<% @set.("#{name}",
    ~s""")
  end

  def endsection() do
    ~s("""\) %>)
  end

  def yield(name) do
    ~s(<%= @get.("#{name}"\) %>)
  end

  def get(id), do: fn key -> ViewEngine.get(id, key) end
  def set(id), do: fn key, value -> ViewEngine.set(id, key, value) end

  # Client
  def start_engine(template_name) do
    template_path = "views/#{template_name}.html.eex"
    engine_name = String.to_atom(template_path)
    # View engine needs to be unique per template to not have overlapping `@section("name")`
    # with the same name.  This needs to be refactored at some point and it's probably
    # barely working.  Will revisit as needed.
    if Process.whereis(engine_name) == nil do
      ViewEngine.start_link(%{"path" => template_path}, name: engine_name)
    end
  end

  def render(template_name, data) do
    template_path = "views/#{template_name}.html.eex"
    engine_name = String.to_atom(template_path)

    # for flexibility, allow string or atom keys
    data =
      for {key, val} <- data, into: %{} do
        if is_atom(key) do
          {key, val}
        else
          {String.to_atom(key), val}
        end
      end

    data =
      Map.merge(
        %{
          include: &include/1,
          section: &section/1,
          endsection: &endsection/0,
          yield: &yield/1,
          extends: &extends/1,
          set: set(engine_name),
          get: get(engine_name),
          errors: %{}
        },
        data
      )

    data = Map.to_list(data)
    # First pass to establish set statements
    statements = EEx.eval_file(template_path, assigns: data)
    # Second pass to execute set statements
    template = EEx.eval_string(statements, assigns: data)
    # Third pass on the template to render the template with stored sections
    placeholders =
      EEx.eval_string(template, assigns: data)
      |> String.replace("{{", "<%=")
      |> String.replace("}}", "%>")

    # Forth pass to render the data
    EEx.eval_string(placeholders, assigns: data) |> String.trim()
  end

  def get(name, key), do: GenServer.call(name, {:get, key})
  def set(name, key, value), do: GenServer.cast(name, {:set, key, value})

  def get_sections(template_path) do
    engine_name = String.to_atom(template_path)
    :sys.get_state(engine_name)
  end
end
