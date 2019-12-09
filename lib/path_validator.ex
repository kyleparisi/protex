defmodule PathValidator do
  import Plug.Conn

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    validations = Router.validate_path(conn.method, conn.path_info, conn)

    errors =
      Enum.reduce(validations, %{}, fn {key, value}, acc ->
        case value do
          {:error, msg} -> Map.put(acc, key, msg)
          _ -> acc
        end
      end)

    if Enum.empty?(errors) do
      params = Enum.into(validations, %{})
      put_in(conn.path_params, params)
    else
      Logger.info("Path failed validations: #{inspect(errors)}")
      assign(conn, :errors, errors)
    end
  end
end
