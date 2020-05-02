defmodule DiopCsv.Controller do

  def parse_to_csv(data, path) do
    case File.open(path, [:write]) do
      {:ok, fd} ->
        IO.write(fd, data |> DiopCsv.Encoder.parse_data)
        File.close(fd)
        {:ok}
      {:error, err} -> {:error, err}
    end
  end

  def read_and_parse(path) do
    case File.read(path) do
      {:ok, res} ->
        {:ok, DiopCsv.Decoder.do_parse(res)}
      {:error, err} ->
        {:error, err}
    end
  end
end
