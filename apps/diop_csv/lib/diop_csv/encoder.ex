defmodule DiopCsv.Encoder do

  def parse_data(data) do
    ## baces path-y u stuges ete karas gres
    #ete ha apa sharunaki datan mechy koxel u grel
    # ete che {:error, error}
    keys = Enum.at(data, 0) |> Map.keys |> Enum.join(",")
    data
      |> Enum.map(fn m -> Map.values(m) |> Enum.join(",") end)
      |> List.insert_at(0, keys)
      |> Enum.join("\n")
  end
end
