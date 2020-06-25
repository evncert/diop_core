defmodule DiopInet do
  @moduledoc """
  Documentation for `DiopInet`.
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_init) do
    DiopInet.Helpers.setup()
    {:ok, %{}}
  end

  def handle_call({:process_file, new_file}, _from, state) do
    spawn(DiopInet.Helpers, :process_file, [new_file])
    {:reply, :ok, state}
  end

  def process_file(new_file) do
    GenServer.call(__MODULE__, {:process_file, new_file})
  end
end
