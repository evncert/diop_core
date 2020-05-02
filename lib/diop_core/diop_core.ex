defmodule DiopCore do
  require Logger

  def check_new_file(path) do
    GenServer.cast(DiopCore.Server, {:new_file, path})
  end
end
