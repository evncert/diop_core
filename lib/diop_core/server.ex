defmodule DiopCore.Server do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state) do
    inputs  = Application.get_env(:diop_core, :inputs)
    Enum.each(inputs, fn input -> spawn(__MODULE__, :check_input, [input]) end)
    {:ok, state}
  end

  def check_input(mod) do
    Logger.debug("checking for #{inspect mod}")
    apply(mod, :start_checking, [])
    :timer.sleep(10000)
    check_input(mod)
  end

  def handle_cast({:new_files, files}, state) do
    Enum.each(files, fn file -> Task.start(DiopCore.Controller, :check_new_file, [file]) end)
    {:noreply, state}
  end
end
