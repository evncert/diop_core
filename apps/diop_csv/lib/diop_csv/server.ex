defmodule DiopCsv.Server do

  use GenServer


  #------------------------------Init------------------------------
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{success: 0, error: 0}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end


  #------------------------------Server API------------------------------
  def handle_call({:parse_csv_file, path}, _from, state) do
    case DiopCsv.Controller.read_and_parse(path) do
      {:ok, res} ->
        {:reply, res, %{state | success: state.success + 1}}
      {:error, err} ->
        {:reply, err, %{state | error: state.error + 1}}
    end
  end

  def handle_call({:data_to_csv, data, path}, _from, state) do
    case DiopCsv.Controller.parse_to_csv(data, path) do
      {:ok} ->
        {:reply, :ok, state}
      {:error, err} ->
        {:reply, err, state}
    end
  end

  def handle_call({:parse_dir, dir_path}, _from, state) do
    with true <- File.dir?(dir_path),
         {:ok, files} <- File.ls(dir_path)
    do
      tasks =
        Enum.map(files,
          fn file -> Task.async(fn -> DiopCsv.Controller.read_and_parse(Path.join(dir_path, file)) end)
          end)
      results = Enum.map(tasks, fn task -> Task.await(task) end)
      {:reply, results, %{state | success: state.success + 1}}
    else
      err -> {:reply, err, %{state | error: state.error + 1}}
    end
  end
end
