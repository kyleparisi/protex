defmodule Remember do
  use Timex

  require Logger

  def init(opts), do: opts

  def handle_remember_cookie(nil = _pid, conn, _opts), do: conn

  def handle_remember_cookie(pid, conn, opts) do
    remember = Map.get(conn.req_cookies, "remember", false)

    remembered_user =
      if remember do
        "SELECT * FROM remember WHERE `key` = ? LIMIT 1;" |> DB.query(:db, [remember])
      else
        []
      end

    if Enum.empty?(remembered_user) do
      conn
    else
      remembered_user = remembered_user |> hd
      expires = Timex.now() |> Timex.shift(weeks: 2) |> DateTime.to_unix()

      "UPDATE remember SET expires = ? WHERE `key` = ? LIMIT 1;"
      |> DB.query(pid, [expires, remember])

      conn = Plug.Conn.put_session(conn, :user_id, remembered_user["user_id"])
      Plug.Conn.put_resp_cookie(conn, "remember", remember, max_age: expires)
    end
  end

  def call(conn, opts) do
    handle_remember_cookie(Process.whereis(:db), conn, opts)
  end
end

