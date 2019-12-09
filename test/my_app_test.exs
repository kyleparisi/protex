defmodule MyAppTest do
  @doc """
  # Notes

  These tests skip the Plug.Parsers in the Pipeline because you need to set the request header for it to work.
  We'll just pass maps as part of the body because it is less verbose.
  """

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

  test "/login with no email and password" do
    conn =
      :post
      |> conn("/login", "")
      |> Pipeline.call([])

    assert conn.status == 422
    assert String.contains?(conn.resp_body, ["Missing email", "Missing password"])
  end

  test "/login with empty email and password" do
    conn =
      :post
      |> conn("/login", %{email: "", password: ""})
      |> Pipeline.call([])

    assert conn.status == 422
    assert String.contains?(conn.resp_body, ["Missing email", "Missing password"])
  end

  test "/login with no password" do
    conn =
      :post
      |> conn("/login", %{email: "test"})
      |> Pipeline.call([])

    assert conn.status == 422
    assert !String.contains?(conn.resp_body, ["Missing email"])
    assert String.contains?(conn.resp_body, ["Missing password"])
  end
end
