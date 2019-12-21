defmodule Remember do
  use Timex

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    remember = Map.get(conn.req_cookies, "remember", false)
    remembered_user = if remember do
      "SELECT * FROM remember WHERE `key` = ? LIMIT 1;" |> DB.query(:db, [remember])
    else
      []
    end
    if Enum.empty?(remembered_user) do
      conn
    else
      remembered_user = remembered_user |> hd
      expires = Timex.now |> Timex.shift(weeks: 2) |> DateTime.to_unix
      "UPDATE remember SET expires = ? WHERE `key` = ? LIMIT 1;" |> DB.query(:db, [expires, remember])
      conn = Plug.Conn.put_session(conn, :user_id, remembered_user["user_id"])
      Plug.Conn.put_resp_cookie(conn, "remember", remember, [max_age: expires])
    end
  end
end
