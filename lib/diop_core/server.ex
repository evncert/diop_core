defmodule DiopCore.Server do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:new_file, path}, state) do
    Task.start(DiopCore.Controller, :check_new_file, [path])
    {:noreply, state}
  end
end
