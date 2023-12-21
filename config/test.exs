import Config

config :my_app, MyApp.Repo,
  username: "postgres",
  password: "postgres",
  database: "myapp_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
