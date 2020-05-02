defmodule DiopCsv.Decoder do

  def do_parse(res) do
    data = res
      |> String.split("\n")
      |> Enum.map(&String.split(&1, ","))
      |> Enum.map(fn line ->line |> Enum.map(fn el -> el |> String.trim("\"" ) end) end)
    [head | tail] = data
    Enum.map(tail, fn values -> push(head, values) end)
  end

  def push(keys, values) do
    Enum.zip(keys, values)
    |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, key, value) end)
  end
end
