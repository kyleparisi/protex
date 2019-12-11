defmodule MyPlug do
  import Plug.Conn
  import Responses

  def include(_data),
    do: fn path ->
      path = String.replace(path, ".", "/")
      EEx.eval_file("./views/#{path}.html.eex")
    end

  def extends(data),
    do: fn path ->
      path = "./views/" <> String.replace(path, ".", "/") <> ".html.eex"

      EEx.eval_file(path,
        assigns: %{
          include: include(data),
          section: &section/1,
          endsection: &endsection/0,
          yield: &yield/1
        }
      )
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

  def init(opts), do: opts

  def call(conn, _opts) do
    res = Router.match(conn.method, conn.path_info, conn)

    # functional middleware
    res =
      if is_function(res) do
        res.(conn)
      else
        res
      end

    # things like put_session modify the connection, so a mechanism to replace the
    # connection in the plug is needed
    {conn, res} =
      case res do
        {:conn, new_conn, new_res} -> {new_conn, new_res}
        _ -> {conn, res}
      end

    case get_req_header(conn, "accept") do
      # Handle explicit json requests
      ["application/json"] ->
        case res do
          {:render, _template_path, data} ->
            json_resp(conn, 200, data)

          _ ->
            json_resp(conn, 200, res)
        end

      # Otherwise, handle the standard signatures
      _ ->
        case res do
          json when is_map(json) ->
            json_resp(conn, 200, json)

          {:redirect, location} ->
            conn = put_resp_header(conn, "location", location)
            send_resp(conn, 301, "")

          {:render, template_path, data} ->
            engine_name = String.to_atom(template_path)

            if Process.whereis(engine_name) == nil do
              ViewEngine.start_link(%{"path" => template_path}, name: engine_name)
            end

            data =
              Map.merge(
                %{
                  include: include(data),
                  section: &section/1,
                  endsection: &endsection/0,
                  yield: &yield/1,
                  extends: extends(data),
                  set: set(engine_name),
                  get: get(engine_name),
                  errors: %{}
                },
                data
              )

            # First pass to establish set statements
            set_statements = EEx.eval_file(template_path, assigns: Map.to_list(data))
            # Second pass to execute set statements
            EEx.eval_string(set_statements, assigns: Map.to_list(data))
            # Third pass to execute to render the template
            str = EEx.eval_string(set_statements, assigns: Map.to_list(data))
            send_resp(conn, 200, "#{String.trim(str)}")

          {http_code, body} ->
            case body do
              json when is_map(json) ->
                json_resp(conn, http_code, json)

              _ ->
                send_resp(conn, http_code, "#{body}\n")
            end

          _ ->
            send_resp(conn, 200, "#{res}\n")
        end
    end
  end
end
