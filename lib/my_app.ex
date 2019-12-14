defmodule MyApp.App do
  use Application

  def start(_type, _args) do
    Application.put_env(:myxql, :json_library, Poison)
    Logger.configure_backend(:console, format: "$time $metadata[$level] $levelpad$message\n")

    children = [
      {Plug.Cowboy,
       scheme: :http,
       plug: nil,
       options: [
         dispatch: dispatch(),
         port: System.get_env("PORT") |> String.to_integer()
       ]},
      {MyXQL,
       username: System.get_env("DB_USERNAME"),
       hostname: System.get_env("DB_HOST"),
       password: System.get_env("DB_PASSWORD"),
       database: System.get_env("DB_DATABASE"),
       name: :db},
      {Phoenix.PubSub, name: MyApp.PubSub}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch() do
    [
      {:_,
       [
         {"/ws", WebSocket, %{}},
         {:_, Plug.Cowboy.Handler, {Pipeline, []}}
       ]}
    ]
  end
end
