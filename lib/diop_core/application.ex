defmodule DiopCore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application


  def get_children() do
    core    = [{DiopCore.Server, []}]
    inputs  = Application.get_env(:diop_core, :inputs) |> Enum.map(fn m -> {m, []} end)
    outputs = Application.get_env(:diop_core, :outputs) |> Enum.map(fn m -> {m, []} end)
    core ++ inputs ++ outputs
  end

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: DiopCore.Supervisor]
    Supervisor.start_link(get_children(), opts)
  end
end
