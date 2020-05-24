use Mix.Config

# Node
node_name =   System.get_env("NODE_NAME")
node_cookie = System.get_env("NODE_COOKIE")

#IMAP
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


config :diop_core,
  node_name: node_name,
  node_cookie: node_cookie

config :eximap,
  account: imap_username,
  password: imap_password,
  use_ssl: true,
  incoming_mail_server: imap_host,
  incoming_port: imap_port


config :diop_email,
  check_list:  ["evncert.am", "pingvinashen.am"]
