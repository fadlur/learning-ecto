import Config

config :friends,
  ecto_repos: [Friends.Repo]

config :friends, Friends.Repo,
  database: "friends",
  username: "postgres",
  password: "147789",
  hostname: "127.0.0.1"
