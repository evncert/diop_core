use Mix.Config

## Node
node_name =   System.get_env("NODE_NAME")
node_cookie = System.get_env("NODE_COOKIE")

## DIOP Core
inputs_list =
  case System.get_env("DIOP_INPUTS") do
    nil -> []
    ins -> ins |> String.split |> Enum.map(fn m -> ("Elixir." <> m) |> String.to_atom end)
  end

outputs_list =
  case System.get_env("DIOP_OUTPUTS") do
    nil -> []
    out -> out |> String.split |> Enum.map(fn m -> ("Elixir." <> m) |> String.to_atom end)
  end

parsers_list =
  case System.get_env("DIOP_PARSERS") do
    nil -> []
    par -> par |> String.split |> Enum.map(fn m -> ("Elixir." <> m) |> String.to_atom end)
  end


## DIOP Network Filter
data_path =
  case System.get_env("DATA_PATH") do
    nil ->
      "/tmp/diop_data/"
    path ->
      path
  end

asn_list =
  case System.get_env("ASN_LIST") do
    nil ->
      []
    asn ->
      asn |> String.split
  end

cidr_list =
  case System.get_env("CIDR_LIST") do
    nil ->
      []
    cidr ->
      cidr |> String.split
  end


## IMAP
imap_username = System.get_env("IMAP_USERNAME")
imap_password = System.get_env("IMAP_PASSWORD")
imap_host =
  case System.get_env("IMAP_HOST") do
    nil   -> "localhost"
    host  -> host
  end

imap_port =
  case System.get_env("IMAP_PORT") do
    nil   -> 993
    port  -> port |> String.to_integer
  end

# Domains to match for IMAP
domains_match_list =
  case System.get_env("DOMAINS_MATCH") do
    nil ->
      nil
    ds  ->
      ds |> String.split
  end


## Configs in Mix.Config
config :diop_core,
  node_name: node_name,
  node_cookie: node_cookie

config :diop_core,
  inputs: inputs_list,
  outputs: outputs_list

config :diop_inet,
  data_path: data_path,
  match_cidr: cidr_list,
  match_asn: asn_list


config :eximap,
  account: imap_username,
  password: imap_password,
  use_ssl: true,
  incoming_mail_server: imap_host,
  incoming_port: imap_port

config :diop_email,
  check_list:  domains_match_list

