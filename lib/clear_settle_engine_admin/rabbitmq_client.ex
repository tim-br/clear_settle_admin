defmodule ClearSettleEngineAdmin.RabbitMQClient do
  use GenServer

  @moduledoc """
  A GenServer client module for interacting with RabbitMQ.
  """

  # API for starting the GenServer
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # GenServer callbacks
  def init(_args) do
    queue = "queue"
    response_exchange = "response_exchange"
    response_queue = "response_queue"

    host = System.get_env("RABBITMQ_HOST") || "localhost"
    {:ok, connection} = AMQP.Connection.open("amqp://guest:guest@#{host}")
    {:ok, channel} = AMQP.Channel.open(connection)
    {:ok, consuming_channel} = AMQP.Channel.open(connection)

    AMQP.Queue.declare(channel, "queue")
    AMQP.Exchange.declare(channel, "start_transactions", :topic, durable: true)
    AMQP.Queue.bind(channel, "queue", "start_transactions")

    AMQP.Queue.declare(consuming_channel, response_queue)
    AMQP.Exchange.declare(consuming_channel, response_exchange, :topic, durable: true)
    AMQP.Queue.bind(consuming_channel, response_queue, response_exchange)

    {:ok, _consumer_tag} =
      AMQP.Basic.consume(
        consuming_channel,
        response_queue,
        nil,
        no_ack: true
      )

    {:ok, %{channel: channel, connection: connection, consuming_channel: consuming_channel}}
  end

  def handle_call({:publish, message}, _from, %{channel: channel} = state) do
    IO.puts("publishing again")
    AMQP.Basic.publish(channel, "start_transactions", "", message)
    {:reply, :ok, state}
  end

  def handle_info(
        {:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}},
        state
      ) do
    # You might want to run payload consumption in separate Tasks in production
    IO.puts("Received in admin: #{payload}")

    Phoenix.PubSub.broadcast(
      ClearSettleEngineAdmin.PubSub,
      "trades_and_balances_updates",
      {"transactions_started", payload}
    )

    {:noreply, state}
  end

  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, state) do
    {:noreply, state}
  end
end
