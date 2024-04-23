defmodule ClearSettleEngineAdminWeb.TradesAndBalancesLive do
  alias ClearSettleEngineSchemas.SecurityBalance
  use ClearSettleEngineAdminWeb, :live_view
  alias Jason, as: JSON
  alias ClearSettleEngineAdmin.{Repo}
  import Ecto.Query, only: [from: 2]

  def mount(_params, _session, socket) do
    # Subscribe to the relevant PubSub topic for real-time updates
    Phoenix.PubSub.subscribe(ClearSettleEngineAdmin.PubSub, "trades_and_balances_updates")

    # Load initial state
    # trades = ClearSettleEngineAdmin.Trades.get_recent_trades()
    ## Repo.preload(SecurityBalance, :account)
    balances = Repo.all(from sb in SecurityBalance, preload: [:account, :security])

    account_mapping = create_account_mapping(balances)
    security_mapping = create_security_mapping(balances)

    transformed_balances =
      Enum.map(balances, fn balance ->
        %{
          "balance" => balance.balance,
          "account_number" => account_mapping[balance.account.id],
          "security_id" => security_mapping[balance.security.id]
        }
      end)

    {:ok,
     assign(socket,
       toast: nil,
       trades: [],
       balances: transformed_balances,
       account_mapping: account_mapping,
       security_mapping: security_mapping
     )}
  end

  def create_account_mapping(balances) do
    Enum.reduce(balances, %{}, fn balance, acc ->
      Map.put(acc, balance.account_id, balance.account.account_number)
    end)
  end

  def create_security_mapping(balances) do
    Enum.reduce(balances, %{}, fn balance, acc ->
      Map.put(acc, balance.security_id, balance.security.security_id)
    end)
  end

  def render(assigns) do
    ClearSettleEngineAdminWeb.TradesAndBalancesView.render("index.html", assigns)
  end

  @impl true
  def handle_event("schedule_trades", _params, socket) do
    GenServer.call(ClearSettleEngineAdmin.RabbitMQClient, {:publish, "no_msg"})
    {:noreply, socket}
  end

  def handle_info({"new_trade", trade_json}, socket) do
    trade = JSON.decode!(trade_json)

    buy_side_account_number =
      socket.assigns.account_mapping[trade["buy_side_account_id"]]

    sell_side_account_number =
      socket.assigns.account_mapping[trade["sell_side_account_id"]]

    security_id = socket.assigns.security_mapping[trade["security_id"]]

    updated_trade =
      Map.merge(trade, %{
        "buy_side_account_number" => buy_side_account_number,
        "sell_side_account_number" => sell_side_account_number,
        "security_id" => security_id
      })
      |> Map.delete("buy_side_account_id")
      |> Map.delete("sell_side_account_id")

    {:noreply, update(socket, :trades, fn trades -> [updated_trade | trades] end)}
  end

  def handle_info({"security_balance_update", balance_json}, socket) do
    new_balance_data = JSON.decode!(balance_json)

    account_number = socket.assigns.account_mapping[new_balance_data["account_id"]]
    security_id = socket.assigns.security_mapping[new_balance_data["security_id"]]

    ## IO.puts("updated balances #{inspect(updated_balance_data}")
    updated_balance_data =
      Map.merge(new_balance_data, %{
        "account_number" => account_number,
        "security_id" => security_id
      })
      |> Map.delete("account_id")

    updated_balances = update_balances(socket.assigns.balances, updated_balance_data)

    {:noreply, assign(socket, balances: updated_balances)}
  end

  @impl true
  def handle_info({"transactions_started", "transactions_started"}, socket) do
    socket =
      assign(socket, :toast, %{
        type: :info,
        message: "Transactions have started successfully."
      })

    Process.send_after(self(), :clear_toast, 1500)

    {:noreply, socket}
  end

  @impl true
  def handle_info({"transactions_started", "already_running"}, socket) do
    IO.puts("in here")

    socket =
      assign(socket, :toast, %{
        type: :error,
        message:
          "Transactions are already running and cannot be started again until current batch has terminated."
      })

    Process.send_after(self(), :clear_toast, 1500)

    {:noreply, socket}
  end

  def handle_info(:clear_toast, socket) do
    {:noreply, assign(socket, toast: nil)}
  end

  def update_balances(balances, new_balance_data) do
    existing_balance_index =
      Enum.find_index(balances, fn balance ->
        balance["account_number"] == new_balance_data["account_number"] and
          balance["security_id"] == new_balance_data["security_id"]
      end)

    case existing_balance_index do
      nil ->
        # No matching balance found, add new balance data to the end of the list
        balances ++ [new_balance_data]

      index ->
        # Update the existing balance
        List.update_at(balances, index, fn balance ->
          Map.merge(balance, new_balance_data)
        end)
    end
  end
end
