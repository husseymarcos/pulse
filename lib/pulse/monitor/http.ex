defmodule Pulse.Monitor.HTTP do
  @moduledoc """
  HTTP client for health checks: connects and sends a GET request via Mint.

  Returns `{:ok, conn, request_ref, start_time}` for streaming, or `{:error, reason}`.
  """

  require Mint.HTTP

  def connect_get(url) do
    uri = URI.parse(url)
    scheme = scheme(uri.scheme)
    host = uri.host
    port = uri.port || default_port(scheme)
    path = path_and_query(uri)
    opts = transport_opts(scheme)

    start_time = System.monotonic_time(:millisecond)

    with {:ok, conn} <- Mint.HTTP.connect(scheme, host, port, opts),
         {:ok, conn, request_ref} <- Mint.HTTP.request(conn, "GET", path, [], nil) do
      {:ok, conn, request_ref, start_time}
    else
      {:error, conn, _reason} when is_struct(conn) ->
        _ = Mint.HTTP.close(conn)
        {:error, :request_failed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp scheme("https"), do: :https
  defp scheme(_), do: :http

  defp default_port(:https), do: 443
  defp default_port(:http), do: 80

  defp path_and_query(uri) do
    path = uri.path || "/"
    if uri.query, do: path <> "?" <> uri.query, else: path
  end

  defp transport_opts(:https), do: [transport_opts: [cacertfile: CAStore.file_path()]]
  defp transport_opts(_), do: []
end
