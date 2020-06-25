defmodule DiopCore do
  require Logger

  def check_new_files(files) do
    GenServer.cast(DiopCore.Server, {:new_files, files})
  end
end
