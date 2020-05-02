defmodule DiopEmail do
  require Logger

  @moduledoc """
  Documentation for DiopEmail.
  """

  @doc """
  For connecting to server.
  """
  def connect_account()  do
    case Eximap.Imap.Client.start_link() do
      {:ok, pid} ->
        {:ok, pid}
      _ ->
        Logger.warn("IMAP start link faild")
        {:error}
    end
  end

  def handle_folders(pid) do
    folders = get_checklist_folders
    current_folders = get_exist_folders(pid)
    folder_list = Enum.filter(folders, fn f -> !Enum.member?(current_folders, f) end)
    Enum.map(folder_list, fn f -> create_folder(f, "INBOX", pid) end)
  end

  def send_nop(pid) do
    Logger.info("sendin noop")
    req = Eximap.Imap.Request.noop
    execute_command(pid, req)
    :timer.sleep(300000)
    send_nop(pid)
  end

  #change function name!!!!
  #stanuma bolor uidnery u hertov stuguma fromy
  def start_matching(pid) do
    request_and_execute(:select, ["INBOX"], pid)
    Logger.debug("listing uids")
    uids = list_uids(pid)
    Logger.info("There are #{length(uids)} mails")
    Enum.map(uids, fn u -> match_msg(pid, u) end)
    clean_mailbox(pid)
    # start_processing(pid)
  end

  def start_processing(pid) do
    folders_list = get_checklist_folders()
    :ok
  end

  #change "INBOX" to normal path :D
  def match_msg(pid, uid) do
    Logger.debug("fetching email")
    res = request_and_execute(:uid, [["FETCH", uid, "BODY.PEEK[HEADER]"]], pid)
    msg = res.body |> List.last |> Map.get(:message)
    from = Regex.run(~r/From: (.*?)\r/, msg) |> tl |> hd
    checking_from(%{from: from, uid: uid}, get_checklist, pid)
  end

  #TODO
  #change folder path "/" to "."
  #call in move
  def create_folder(folder_name, folder_path, pid) do
    # target = folder_path <> "." <> folder_name
    req = request_and_execute(:create, [folder_name], pid)
    # execute_command(pid, req)
  end

  def clean_mailbox(pid) do
    request_and_execute(:expunge, [], pid)
  end

  #TODO
  #sendon request close and execute req.
  #stop calling noop
  def imap_close() do
  end

  def logout() do
  end

  def close_socket() do
  end

  def close_gen_server() do
  end

  def check_file_type(path) do
    MIME.from_path(path)
    GenServer.call(DiopCore.Server, {:new_file, path})
  end

#-----------------------------------Healper functions--------------------------------------

  defp request_and_execute(command, args, pid) do
    req = apply(Eximap.Imap.Request, command, args)
    execute_command(pid, req)
  end

  defp execute_command(pid, request) do
    res = Eximap.Imap.Client.execute(pid, request)
    case res.status do
      "OK" -> Logger.info("Check completed")
      "BAD" -> Logger.info("Invalid arguments")
    end
    res
  end

  defp copy_msg(pid, uid, dest) do
    request_and_execute(:uid, [["COPY", uid, dest]], pid)
  end

  defp delete_msg(pid, uid) do
    request_and_execute(:uid, [["STORE", uid, "+FLAGS", "\\Deleted"]], pid)
  end

  def select_folder(pid, folder) do
    request_and_execute(:select, [folder], pid)
  end

  def list_uids(pid) do
    Logger.debug("running fetch")
    res = request_and_execute(:uid, [["FETCH", "1:*", "(UID)"]], pid)
    res.body
    |> Enum.reject(fn e -> e == %{} end) |> Enum.map(fn e -> e.message |> (&Regex.run(~r/UID (.*)\)/, &1)).() |> tl end)
    |> List.flatten
    |> Enum.sort
  end

  def checking_from(%{from: from, uid: uid}, match_list, pid) do
    case Enum.find(match_list, fn l -> String.contains?(from, l) end) do
      nil ->
        Logger.debug("message #{uid} is useless")
      match  ->
        move_msg(pid, uid, match |> String.replace(".", ""))
        Logger.debug("message #{uid} moved")
    end
  end

  def move_msg(pid, uid, dest) do
    copy_msg(pid, uid, dest)
    delete_msg(pid, uid)
  end

  def get_exist_folders(pid) do
    req = Eximap.Imap.Request.list()
    res = execute_command(pid, req)
    res.body
    |> Enum.reject(fn m -> m == %{} end)
    |> Enum.map(fn m -> m.message
    |> (&Regex.run(~r/ (\w+)$/, &1)).() |> tl end)
    |> List.flatten
  end

  def get_checklist do
    Application.get_env(:diop_email, :check_list)
  end

  def get_checklist_folders do
    get_checklist |> Enum.map(fn f -> String.replace(f, ".", "") end)
  end

  def get_attachments(pid, uid) do
    #req = Eximap.Imap.Request.uid(["FETCH",uid,"(BODYSTRUCTURE.ATTACHMENTS)"])
    req = Eximap.Imap.Request.uid(["FETCH", uid, "RFC822"])
    res = Eximap.Imap.Client.execute(pid, req)
    filter_body(res.body)
  end

  def filter_body(body) do
    body
    |> Enum.reject(fn m -> m == %{} end)
    |> hd()
    |> Map.get(:message)
    |> parse_email()
  end

  def parse_email(mail_raw) do
    Mail.Parsers.RFC2822.parse(mail_raw)
    |> Mail.get_attachments
    |> find_zips
  end

  def find_zips(attach_list) do
    attach_list
    |> Enum.filter(fn {name, _data} -> String.contains?(name, "zip") end)
    |> write_files()
  end

  def write_files(files_and_data) do
    files_and_data
    |> Enum.map(fn {name, data} -> :zip.extract(data, [:memory]) end)
  end
end
