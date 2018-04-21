defmodule Conduit.TestAdapter do
  use Conduit.Adapter
  use Supervisor

  @moduledoc """
  This module is intended to be used instead of a normal adapter in tests.

  See `Conduit.Test` for details.
  """

  def child_spec([broker, _, _, _] = args) do
    %{
      id: Module.concat(broker, Adapter),
      start: {__MODULE__, :start_link, args},
      type: :supervisor
    }
  end

  @doc false
  def start_link(broker, topology, subscribers, opts) do
    Supervisor.start_link(__MODULE__, [broker, topology, subscribers, opts])
  end

  @doc false
  def init(opts) do
    import Supervisor.Spec

    process = Application.get_env(:conduit, :shared_test_process)
    if process, do: send(process, {:adapter, opts})

    supervise([], strategy: :one_for_one)
  end

  @doc """
  Sends a publish message to the current process or the shared_test_process
  if that is configured.
  """
  def publish(broker, message, config, opts) do
    process = Application.get_env(:conduit, :shared_test_process, self())
    send(process, {:publish, broker, message, config, opts})

    message
  end
end
