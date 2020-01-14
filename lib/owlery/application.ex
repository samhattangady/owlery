defmodule Owlery.Application do
  @moduledoc false

  use Application

  def start(type, args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Registry, [:unique, :owlery_registry]),
      worker(Owlery.Owlery, [type, args])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Owlery.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
