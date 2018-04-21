defmodule Conduit.Broker do
  @moduledoc """
  Defines a Conduit Broker.

  The broker is the boundary between your application and a
  message queue. It allows the setup of a message queue and
  provides a DSL for handling incoming messages and outgoing
  messages.
  """

  @doc """
  Sets the broker up as a `Supervisor` and includes the
  `Conduit.Broker.DSL`.
  """
  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise("endpoint expects :otp_app to be given")
      use Supervisor
      use Conduit.Broker.DSL, otp_app: @otp_app

      def start_link(opts \\ []) do
        Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def child_spec(_) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, []},
          type: :supervisor
        }
      end

      def init(_opts) do
        Conduit.Broker.init(@otp_app, __MODULE__, topology(), subscribers())
      end
    end
  end

  @doc false
  def init(otp_app, broker, topology, subscribers) do
    config = Application.get_env(otp_app, broker)
    adapter = Keyword.get(config, :adapter) || raise Conduit.AdapterNotConfiguredError

    subs =
      subscribers
      |> Enum.map(fn {name, {_, opts}} ->
        {name, opts}
      end)
      |> Enum.into(%{})

    children = [
      {adapter, [broker, topology, subs, config]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc false
  def raw_publish(otp_app, broker, message, opts) do
    config = Application.get_env(otp_app, broker)
    adapter = Keyword.get(config, :adapter)

    adapter.publish(broker, message, config, opts)
  end
end
