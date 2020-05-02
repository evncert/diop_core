defmodule DiopCore.Database do
  require Record
  require Logger
  use GenServer

  Record.defrecord(:core_db, id: nil, timestamp: nil, source: nil, source_id: nil, raw_data: nil)
  @type core_db :: record(:core_db,
    id: integer(),
    timestamp: integer(),
    source: String.t(),
    source_id: String.t(),
    raw_data: any()
  )

  def start_link(_) do
    data = %{
      nodes: [node()],
      table_props: [attributes: core_db() |> core_db() |> Keyword.keys()],
      table_name: :core_db
    }
    GenServer.start_link(__MODULE__, data, name: __MODULE__)
  end

  def init(data) do
    case check_mnesia_prestart(data) do
      :done ->
        {:ok, data}
      :shotdown ->
        {:error, :"oopsik pupsik"}
    end
  end

  #TODO improve code because legacy
  def check_mnesia_prestart(data) do
    data
    |> start
    |> create_table(data)
    |> wait_for_table(data)
    |> finale_func
  end

  defp start(_) do
    :mnesia.start
  end

  defp create_table(arg, data) do
    case arg do
      :ok ->
        :mnesia.create_table(data.table_name, data.table_props)
      {:error, msg} ->
        Logger.error("oops got #{msg}")
        :shutdown
    end
  end

  defp wait_for_table(arg, data) do
    case arg do
      {:aborted, {:already_exists, table_name}} ->
        Logger.info("table already existed -> #{table_name}")
        :mnesia.wait_for_tables([data.table_name], 5000)
      {:atomic, :ok} ->
        :mnesia.wait_for_tables([data.table_name], 5000)
      :shutdown -> :shutdown
      other ->
        Logger.error("#{inspect other}")
        :shutdown
      end
  end

  defp finale_func(arg) do
    case arg do
      :ok -> :done
      {:timeout, table} ->
        Logger.error("timoute on table #{inspect table}")
        :shutdown
      {:error, reason} ->
        Logger.error("error on table #{inspect reason}")
        :shutdown
      :shutdown -> :shutdown
    end
  end

  def write_data(record)do
    (fn -> :mnesia.write(record) end)
    |> :mnesia.transaction()
  end
end
