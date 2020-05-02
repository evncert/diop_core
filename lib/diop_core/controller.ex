defmodule DiopCore.Controller do
  require Logger

  def check_new_file(path) do
    Logger.debug("new file at #{path}")
    case MIME.from_path(path) do
      mime_type ->
        :ok
    end
  end
end
