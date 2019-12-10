defmodule Router do
  import Validations

  require Logger

  def validate_body("POST", ["login"], conn),
    do: [
      validate_not_empty("email", conn.body_params["email"]),
      validate_not_empty("password", conn.body_params["password"])
    ]

  def validate_body("POST", ["sign-up"], conn),
    do: [
      validate_not_empty("email", conn.body_params["email"]),
      validate_not_empty("password", conn.body_params["password"])
    ]

  def validate_body(_, _, _), do: []

  def validate_path("GET", ["user", id], _conn), do: [validate_integer("id", id)]
  def validate_path(_, _, _), do: []

  def match("GET", ["health"], _conn) do
    "Ok"
  end

  def match("GET", ["hello", name], _conn) do
    "Hello #{name}"
  end

  def match("GET", ["hello2", name], _conn) do
    {:render, "views/hello.html.eex", %{name: name}}
  end

  def match("GET", ["user", _id], conn) do
    "SELECT * FROM user where id = ?" |> DB.query(:db, [conn.path_params["id"]]) |> hd
  end

  def match("GET", "/login", _conn) do
    {:render, "views/login.html.eex", %{}}
  end

  def match("POST", ["login"], %{assigns: %{errors: errors}} = conn) do
    {:render, "views/login.html.eex", %{errors: errors, email: conn.body_params["email"]}}
  end

  def match("GET", ["sign-up"], _conn) do
    {:render, "views/sign-up.html.eex", %{}}
  end

  def match("POST", ["sign-up"], %{assigns: %{errors: errors}} = conn) do
    {:render, "views/sign-up.html.eex", %{errors: errors, email: conn.body_params["email"]}}
  end

  def match("POST", ["sign-up"], conn) do
    %{"email" => email, "password" => password} = conn.body_params

    not_a_user =
      "SELECT * FROM user where email = ? LIMIT 1;" |> DB.query(:db, [email]) |> Enum.empty?()

    if not_a_user do
      hash = Argon2.hash_pwd_salt(password)

      %{id: id} =
        "INSERT INTO user SET email=?, password=?, forgot_token=?, verified_email=?, role='user'"
        |> DB.query(:db, [email, hash, "", false])

      conn = Plug.Conn.put_session(conn, :user_id, id)

      {:conn, conn, {:redirect, "/dashboard"}}
    else
      Logger.info("User already exists. #{email}")
      {:render, "views/sign-up.html.eex",
       %{errors: %{"exists" => "User already exists."}, email: email}}
    end
  end

  def match("GET", ["session"], conn) do
    str = :crypto.strong_rand_bytes(5) |> Base.url_encode64() |> binary_part(0, 5)
    conn = Plug.Conn.put_session(conn, :test, str)
    {:conn, conn, Plug.Conn.get_session(conn)}
  end

  def match(_, _, _) do
    {:not_found, "Not Found"}
  end
end
