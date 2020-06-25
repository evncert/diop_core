defmodule DiopEmail do

  require Logger
  use GenServer


  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Initialising connect account and creating folders.
  """
  def init(_init) do
    case DiopEmail.Helpers.connect_account() do
      {:ok, pid} ->
        DiopEmail.Helpers.handle_folders(pid)
        spawn(fn -> DiopEmail.Helpers.send_noop(pid) end)
        {:ok, %{pid: pid}}
      _ ->
        Logger.warn("Getting pid failed")
        {:error, "shit happened"}
    end
  end

  def handle_cast({:start_checking}, state) do
    pid = state.pid
    spawn(DiopEmail.Helpers, :start_matching, [pid])
    {:noreply, state}
  end

  def handle_call({:get_pid}, state) do
    {:reply, state.pid, state}
  end

  def handle_call({:get_stats}, state) do
    stats = "nothing for now"
    {:reply, stats, state}
  end

  def terminate(_, _state) do
    Logger.info("Logging out of IMAP")
    Logger.info("Cleaning up DB")
    Logger.info("Done. Bye!")
    :ok
  end

  def start_checking do
    GenServer.cast(DiopEmail, {:start_checking})
  end
end
