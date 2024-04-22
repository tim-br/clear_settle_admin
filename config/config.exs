# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :clear_settle_engine_admin,
  ecto_repos: [ClearSettleEngineAdmin.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :clear_settle_engine_admin, ClearSettleEngineAdminWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [
      html: ClearSettleEngineAdminWeb.ErrorHTML,
      json: ClearSettleEngineAdminWeb.ErrorJSON
    ],
    layout: false
  ],
  pubsub_server: ClearSettleEngineAdmin.PubSub,
  live_view: [signing_salt: "kLC5F5Sh"]

config :clear_settle_engine, ClearSettleEngine.Repo,
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", ""),
  database: System.get_env("DB_DATABASE", "clear_settle_engine_dev"),
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432"),
  ssl: true,
  ssl_opts: [verify: :verify_none],
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "10"))

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :clear_settle_engine_admin, ClearSettleEngineAdmin.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
