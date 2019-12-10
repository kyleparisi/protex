defmodule MyPlug do
  import Plug.Conn
  import Responses

  def include(path) do
    IO.inspect path
    IO.inspect String.replace(path, ".", "/")
    path = "./views/" <> String.replace(path, ".", "/") <> ".html.eex"
    EEx.eval_file(path)
  end

  def extends(path) do
    path = "./views/" <> String.replace(path, ".", "/") <> ".html.eex"
    body = EEx.eval_file(path, assigns: %{include: &MyPlug.include/1, section: &section/1, endsection: &endsection/0, yield: &yield/1})
  end

  def section(name) do
    "<% #{name} = "
  end

  def endsection() do
    "%>"
  end

  def yield(name) do
    "<%= #{name} %>"
  end

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
            data = Map.merge(data, %{include: &include/1, section: &section/1, endsection: &endsection/0, yield: &yield/1, extends: &extends/1})
            body = EEx.eval_file(template_path, assigns: Map.to_list(data))
            send_resp(conn, 200, "#{String.trim(body)}")

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
