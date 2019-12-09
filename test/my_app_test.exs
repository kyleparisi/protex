defmodule MyAppTest do
  use ExUnit.Case
  use Plug.Test
  doctest MyApp.App

  test "/health returns ok" do
    conn =
      :get
      |> conn("/health", "")
      |> MyPlug.call([])

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Ok\n"
  end


end
