defmodule Pulse.Web do
  @moduledoc """
  HTTP API for the TUI and other clients.

  GET /health   — health check (JSON: {"status":"ok"}).
  GET /services — list monitored services (JSON: id, name, url, latency_ms).
  POST /services — add a service (JSON body: name, url). Returns 201 or error.
  """
require Logger

  use Plug.Router

  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  get "/health" do
    json(conn, 200, %{status: "ok"})
  end

  get "/services" do
    json(conn, 200, Pulse.Monitor.list_services())
  end

  post "/services" do
    case conn.body_params do
      %{"name" => name, "url" => url} when is_binary(name) and is_binary(url) ->
        name = String.trim(name)
        url = String.trim(url)
        if name == "" or url == "", do: json(conn, 400, %{error: "name and url are required"}),
        else: add_service(conn, name, url)

      _ ->
        json(conn, 400, %{error: "body must include name and url (strings)"})
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp json(conn, status, body), do:
    conn |> put_resp_content_type("application/json") |> send_resp(status, Jason.encode!(body))

  defp add_service(conn, name, url) do
    service = %Pulse.Service{name: name, url: url}
    case Pulse.Monitor.add_service(service) do
      :ok ->
        if service.id, do: Pulse.Monitor.check(service.id)
        json(conn, 201, service)

      {:error, :already_exists} ->
        json(conn, 409, %{error: "Service with this URL already exists"})

      {:error, _} ->
        json(conn, 500, %{error: "Failed to add service"})
    end
  end
end
