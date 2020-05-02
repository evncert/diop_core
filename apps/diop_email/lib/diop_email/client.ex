defmodule DiopEmail.Client do

  def start_checking do
    GenServer.cast(DiopEmail.Server, {:start_checking})
  end
end
