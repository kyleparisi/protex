defmodule MyPlug do
  import Plug.Conn

  def init(opts), do: opts

  def json_resp(conn, status, body) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(status, Poison.encode!(body) <> "\n")
  end

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
            ViewEngine.start_engine(template_path)

            data =
              Map.merge(
                %{
                  body_params: conn.body_params,
                  session: Plug.Conn.get_session(conn)
                },
                data
              )

            view = ViewEngine.render(template_path, data)
            send_resp(conn, 200, view)

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
