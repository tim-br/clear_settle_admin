defmodule ClearSettleEngineAdmin.Repo do
  use Ecto.Repo,
    otp_app: :clear_settle_engine_admin,
    adapter: Ecto.Adapters.Postgres
end
