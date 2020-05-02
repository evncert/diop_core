defmodule DiopCsv do

  def parse_csv_file(path) do
    GenServer.call(DiopCsv.Server, {:parse_csv_file, path}, 10000)
  end

  def data_to_scv(data, path) do
    GenServer.call(DiopCsv.Server, {:data_to_csv, data, path}, 10000)
  end

  def parse_dir(path) do
    GenServer.call(DiopCsv.Server, {:parse_dir, path}, 10000)
  end
end
