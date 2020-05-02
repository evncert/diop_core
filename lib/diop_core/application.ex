defmodule DiopCore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: DiopCore.Worker.start_link(arg)
      # {DiopCore.Worker, arg}
      {DiopCore.Server, []},
      {DiopCore.Database, []},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DiopCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
