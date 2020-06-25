defmodule DiopCore.Controller do
  require Logger

  def check_new_file(path) do
    outputs = Application.get_env(:diop_core, :outputs)
    Logger.debug("new file at #{path}")
    Enum.each(outputs, fn o -> apply(o, :process_file, [path]) end)
  end
end
