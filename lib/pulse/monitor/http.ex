defmodule Pulse.Monitor.HTTP do
  @moduledoc "Mint GET for health checks. Returns {:ok, conn, request_ref, start_time} | {:error, reason}."
  require Mint.HTTP

  def connect_get(url) do
    uri = URI.parse(url)
    scheme = if uri.scheme == "https", do: :https, else: :http
    port = uri.port || (if scheme == :https, do: 443, else: 80)
    path = (uri.path || "/") |> then(fn p -> if uri.query, do: p <> "?" <> uri.query, else: p end)
    opts = if scheme == :https, do: [transport_opts: [cacertfile: CAStore.file_path()]], else: []
    start = System.monotonic_time(:millisecond)

    with {:ok, conn} <- Mint.HTTP.connect(scheme, uri.host, port, opts),
         {:ok, conn, ref} <- Mint.HTTP.request(conn, "GET", path, [], nil) do
      {:ok, conn, ref, start}
    else
      {:error, conn, _} -> _ = Mint.HTTP.close(conn); {:error, :request_failed}
      {:error, reason} -> {:error, reason}
    end
  end
end
