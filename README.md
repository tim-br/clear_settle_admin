# ClearSettleEngineAdmin

#### Configuration:
Update `dev.exs` with your PostgreSQL credentials:
```elixir
config :clear_settle_engine_admin, ClearSettleEngineAdmin.Repo,
  username: "your_username",
  password: "your_password",
  hostname: "localhost",
  database: "clear_settle_engine_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

To start your server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

For viewing data from the admin interface, please refer to [Clear Settle Engine repository on GitHub](https://github.com/tim-br/clear_settle_engine). This repository offers tools and scripts that integrate seamlessly with ClearSettleEngineAdmin, allowing for a comprehensive view and interaction with live market events through the admin interface.