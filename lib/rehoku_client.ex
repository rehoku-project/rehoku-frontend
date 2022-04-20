defmodule RehokuClient do
  @filepath ".rehoku"

  def main(_) do
    HTTPoison.start()
    start()
  end

  def start() do
    case System.argv() do
      ["deploy"] ->
        if !File.exists?(@filepath) do
          configure_app()
        end

        get_hostname_from_config()
        |> deploy_app()

      ["config"] ->
        if File.exists?(@filepath) do
          overwrite_file()
        end

        configure_app()

      ["config", "show"] ->
        if !File.exists?(@filepath) do
          IO.puts("Config file does not exist!")
        end

        show_config()

      _ ->
        """
        Unknown argument.
        Possible arguments:
        * deploy
        * config
        * config show
        """
        |> IO.puts()

        System.halt(0)
    end
  end

  def deploy_app(hostname) do
    case HTTPoison.get("https://#{hostname}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts(body)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end

    IO.puts("Deployed to #{hostname}!")
  end

  def configure_app() do
    hostname = IO.gets("Provide the hostname of your server\n")

    if valid_hostname?(hostname) do
      write_hostname_to_file(hostname)
    else
      IO.puts("Provided hostname is incorrect")
      System.halt(0)
    end
  end

  def overwrite_file() do
    answer =
      """
      Do you want to overwrite your config file?\n
      Type "yes" to accept.
      """
      |> IO.gets()
      |> String.trim()

    case answer do
      "yes" ->
        :ok

      _ ->
        IO.puts("Config file not modified, exiting.")
        System.halt(0)
    end
  end

  def write_hostname_to_file(hostname) do
    File.write(@filepath, "hostname = #{hostname}", [:write, {:encoding, :utf8}])
  end

  def valid_hostname?(hostname) do
    hostname_regex = ~r/^((?!-)[A-Za-z0-9-]{1,63}(?<!-)\.)+[A-Za-z]{2,6}$/

    ip_regex =
      ~r/^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/

    localhost_regex = ~r/^localhost$/

    cond do
      String.match?(hostname, hostname_regex) -> true
      String.match?(hostname, ip_regex) -> true
      String.match?(hostname, localhost_regex) -> true
      true -> false
    end
  end

  def get_hostname_from_config() do
    {:ok, contents} = File.read(@filepath)

    contents
    |> String.split("=", trim: true)
    |> List.last()
    |> String.trim()
  end

  def show_config() do
    {:ok, contents} = File.read(@filepath)
    contents |> IO.puts()
  end
end
