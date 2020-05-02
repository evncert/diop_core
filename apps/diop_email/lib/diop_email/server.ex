defmodule DiopEmail.Server do
  require Logger
  use GenServer


  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_init) do
    #TODO do proper case handling
    {:ok, pid} = DiopEmail.connect_account()
    DiopEmail.handle_folders(pid)
    #TODO use proper Link
    spawn(fn -> DiopEmail.send_nop(pid) end)
    {:ok, %{pid: pid}}
  end

  def handle_cast({:start_checking}, state) do
    pid = state.pid
    spawn(DiopEmail, :start_matching, [pid])
    {:noreply, state}
  end

  def handle_call({:get_pid}, state) do
    {:reply, state.pid, state}
  end

  def handle_call({:get_stats}, state) do
    stats = "nothing for now"
    {:reply, stats, state}
  end

  def terminate(_, state) do
    Logger.info("Logging out of IMAP")
    Logger.info("Cleaning up DB")
    Logger.info("Done. Bye!")
    :ok
  end
end
