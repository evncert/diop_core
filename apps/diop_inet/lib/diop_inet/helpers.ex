defmodule DiopInet.Helpers do
  require Logger

  def setup() do
    path = get_data_path()

    get_asns()
    |> create_dir(path)

    get_cidr()
    |> create_dir(path)
  end

  def process_file(new_file) do
    Enum.each(get_asns(), fn asn -> spawn(__MODULE__, :process_asn, [new_file, asn]) end)
    Enum.each(get_cidr(), fn range -> spawn(__MODULE__, :process_cidr, [new_file, range]) end)
  end

  def process_asn(new_file, net) do
    file_name = new_file |> Path.basename
    {:ok, fd} = File.open(Path.join(get_data_path(), net) |> Path.join(file_name), [:append])
    {:ok, data} = File.read(new_file)
    data_lines = data |> String.split("\n")
    IO.write(fd, data_lines |> hd)
    IO.write(fd, "\n")
    #TODO write concurrently
    IO.write(fd,
      data_lines
      |> Enum.filter(fn l -> l |> String.contains?(net) end)
      |> Enum.join("\n")
    )
    IO.write(fd, "\n")
    File.close(fd)
  end

  def process_cidr(new_file, cidr) do
    file_name = new_file |> Path.basename
    {:ok, fd} = File.open(Path.join(get_data_path(), cidr) |> Path.join(file_name), [:append])
    {:ok, data} = File.read(new_file)
    data_lines = data |> String.split("\n")
    IO.write(fd, data_lines |> hd)
    IO.write(fd, "\n")
    #TODO write concurrently
    cidrt = InetCidr.parse(cidr |> String.replace("-", "/"))
    IO.write(fd,
      data_lines
      |> Enum.filter(fn l -> l |> process_line(cidrt) end)
      |> Enum.join("\n")
    )
    IO.write(fd, "\n")
    File.close(fd)
  end

  def process_line(row, cidrt) do
    addrs = get_ips_from_row(row)
    Enum.any?(addrs, fn addr -> InetCidr.contains?(cidrt, addr) end)
  end

  def get_ips_from_row(row) do
    case Regex.scan(~r/\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b/, row) do
      nil   -> []
      []    -> []
      addr  -> Enum.map(addr, fn l -> l |> hd |> InetCidr.parse_address! end)
    end
  end

  def get_asns() do
    Application.get_env(:diop_inet, :match_asn)
  end

  def get_cidr() do
    Application.get_env(:diop_inet, :match_cidr)
    |> Enum.map(fn r -> r |> String.replace("/", "-") end)
  end

  def get_data_path() do
    Application.get_env(:diop_inet, :data_path)
  end

  def get_dir_list() do
    asns = Enum.map(get_asns(), fn a -> Path.join(get_data_path(), a) end)
    cidr = Enum.map(get_cidr(), fn i -> Path.join(get_data_path(), i) end)
    asns ++ cidr
  end

  def create_dir(dir_name_list, path) do
    dir_name_list |> Enum.each(fn d -> File.mkdir_p(Path.join(path, d)) end)
  end
end
