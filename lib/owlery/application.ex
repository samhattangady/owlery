defmodule Owlery.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Registry, [:unique, :owlery_registry])
      # Starts a worker by calling: Owlery.Worker.start_link(arg)
      # {Owlery.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Owlery.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
