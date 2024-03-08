defmodule NotificationListener do
  use GenServer

  # Starts the GenServer
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Initializes the NotificationListener
  def init(:ok) do
    # Assuming ClearSettleEngine.Repo is your Ecto Repo
    {:ok, pid} = Postgrex.Notifications.start_link(ClearSettleEngineAdmin.Repo.config())
    # Listen to the notifications
    Postgrex.Notifications.listen(pid, "new_trade")
    Postgrex.Notifications.listen(pid, "security_balance_update")
    {:ok, pid}
  end

  # Handles incoming notifications
  def handle_info({:notification, _pid, _ref, channel, payload}, state) do
    ## IO.puts("Received notification on channel #{channel}: #{payload}")

    Phoenix.PubSub.broadcast(
      ClearSettleEngineAdmin.PubSub,
      "trades_and_balances_updates",
      {channel, payload}
    )

    {:noreply, state}
  end
end
