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

    assert String.contains?(conn.resp_body, ["Missing email", "Missing password"])
  end

  test "/login with empty email and password" do
    conn =
      :post
      |> conn("/login", %{email: "", password: ""})
      |> Pipeline.call([])

    assert String.contains?(conn.resp_body, ["Missing email", "Missing password"])
  end

  test "/login with no password" do
    conn =
      :post
      |> conn("/login", %{email: "test"})
      |> Pipeline.call([])

    assert !String.contains?(conn.resp_body, ["Missing email"])
    assert String.contains?(conn.resp_body, ["Missing password"])
  end

  test "/sign-up with no email or password" do
    conn =
      :post
      |> conn("/sign-up", "")
      |> Pipeline.call([])

    assert String.contains?(conn.resp_body, ["Missing email", "Missing password"])
  end

  test "/sign-up" do
    conn =
      :post
      |> conn("/sign-up", %{"email" => "test@test.com", "password" => "test"})
      |> Pipeline.call([])

    session = Plug.Conn.get_session(conn)
    assert session["user_id"] == 1
    assert conn.status == 301
  end

  test "/sign-up when user already exists" do
    conn =
      :post
      |> conn("/sign-up", %{email: "test@test.com", password: "test"})
      |> Pipeline.call([])

    assert String.contains?(conn.resp_body, ["User already exists"])
  end

  test "/login" do
    conn =
      :post
      |> conn("/login", %{"email" => "test@test.com", "password" => "test"})
      |> Pipeline.call([])

    assert conn.status == 301
    session = Plug.Conn.get_session(conn)
    assert session["user_id"] == 1
  end

  test "/dashboard restricted to logged in users" do
    conn =
      :get
      |> conn("/dashboard")
      |> Pipeline.call([])

    assert conn.status == 301
  end
end
