defmodule DiopEmail.Helpers do
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

  @doc """
  Creating folders exist in checklist.
  """
  def handle_folders(pid) do
    folders = get_checklist_folders()
    current_folders = get_existing_folders(pid)
    missing_folders_list = Enum.filter(folders, fn f -> !Enum.member?(current_folders, f) end)
    Enum.map(missing_folders_list, fn f -> create_folder(f, "INBOX", pid) end)
  end

  def send_noop(pid) do
    Logger.debug("sendin noop")
    req = Eximap.Imap.Request.noop
    execute_command(pid, req)
    :timer.sleep(300000)
    send_noop(pid)
  end

  def start_matching(pid) do
    select_folder(pid, "INBOX")
    Logger.debug("listing uids")
    uids = list_all_uids(pid)
    Logger.info("There are #{length(uids)} mails")
    Enum.each(uids, fn u -> match_email(pid, u) end)
    clean_mailbox(pid)
    start_processing()
  end

  def start_processing() do
    folders = get_checklist_folders()
    Enum.each(folders, fn folder -> connect_account() |> process(folder) end)
  end

  defp process({:error}, _folder) do
    Logger.warn("could not connect")
  end

  defp process({:ok, pid}, folder) do
    select_folder(pid, folder)
    unread_mails = list_unread_uids(pid)
    case unread_mails do
      nil ->
        logout(pid)
        :ok
      "" ->
        logout(pid)
        :ok
      uids ->
        Enum.each(uids |> String.split(), fn uid -> spawn(__MODULE__, :get_attachments, [pid, uid]) end)
    end
  end

  #change "INBOX" to normal path :D
  def match_email(pid, uid) do
    Logger.debug("fetching email")
    res   = request_and_execute(:uid, [["FETCH", uid, "BODY.PEEK[HEADER]"]], pid)
    msg   = res.body |> List.last |> Map.get(:message)
    from  = Regex.run(~r/From: (.*?)\r/, msg) |> tl |> hd

    check_header_from(%{from: from, uid: uid}, get_checklist(), pid)
  end

  def create_folder(folder_name, _folder_path, pid) do
    request_and_execute(:create, [folder_name], pid)
  end

  def clean_mailbox(pid) do
    request_and_execute(:expunge, [], pid)
  end

  #TODO
  def imap_close() do
  end

  def logout(pid) do
    req = Eximap.Imap.Request.logout()
    Eximap.Imap.Client.execute(pid, req)
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

  defp copy_email(pid, uid, dest) do
    request_and_execute(:uid, [["COPY", uid, dest]], pid)
  end

  defp delete_email(pid, uid) do
    request_and_execute(:uid, [["STORE", uid, "+FLAGS", "\\Deleted"]], pid)
  end

  def select_folder(pid, folder) do
    request_and_execute(:select, [folder], pid)
  end

  def list_all_uids(pid) do
    Logger.debug("running fetch")
    res = request_and_execute(:uid, [["FETCH", "1:*", "(UID)"]], pid)
    res.body
    |> Enum.reject(fn e -> e == %{} end) |> Enum.map(fn e -> e.message |> (&Regex.run(~r/UID (.*)\)/, &1)).() |> tl end)
    |> List.flatten
    |> Enum.sort
  end

  def list_unread_uids(pid) do
    res = request_and_execute(:search, [["UNSEEN"]], pid)
    res.body
    |> Enum.find(fn m -> Map.get(m, :type) == "SEARCH" end)
    |> Map.get(:message)
  end

  def check_header_from(%{from: from, uid: uid}, match_list, pid) do
    case Enum.find(match_list, fn l -> String.contains?(from, l) end) do
      nil ->
        Logger.debug("message #{uid} is useless")
      match  ->
        move_email(pid, uid, match |> String.replace(".", ""))
        Logger.debug("message #{uid} moved")
    end
  end

  def move_email(pid, uid, dest) do
    copy_email(pid, uid, dest)
    delete_email(pid, uid)
  end

  def get_existing_folders(pid) do
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
    get_checklist() |> Enum.map(fn f -> String.replace(f, ".", "") end)
  end

  def get_attachments(pid, uid) do
    req = Eximap.Imap.Request.uid(["FETCH", uid, "RFC822"])
    res = Eximap.Imap.Client.execute(pid, req)
    filter_body(res.body)
    logout(pid)
  end

  defp filter_body(body) do
    body
    |> Enum.reject(fn m -> m == %{} end)
    |> hd()
    |> Map.get(:message)
    |> parse_email()
  end

  defp parse_email(mail_raw) do
    Mail.Parsers.RFC2822.parse(mail_raw)
    |> Mail.get_attachments
    |> find_zips
  end

  defp find_zips(attach_list) do
    attach_list
    |> Enum.filter(fn {name, _data} -> String.contains?(name, "zip") end)
    |> write_files()
  end

  defp write_files(files_and_data) do
    path = Application.get_env(:diop_inet, :data_path) |> to_charlist
    files_and_data
    |> Enum.map(fn {_name, data} -> :zip.extract(data, [{:cwd, path}]) end)
    |> Enum.filter(fn f -> elem(f, 0) == :ok end) |> Enum.map(fn f -> elem(f, 1) |> to_string end) |> List.flatten
    |> notify_core()
  end

  defp notify_core(files) do
    GenServer.cast(DiopCore.Server, {:new_files, files})
  end
end
