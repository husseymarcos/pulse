defmodule Pulse.Web do
  @moduledoc """
  HTTP API for the TUI and other clients.

  GET /health  — health check (JSON: {"status":"ok"}).
  GET /services — list monitored services (JSON: id, name, url, latency_ms).
  """

  use Plug.Router

  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  get "/health" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"status":"ok"}))
  end

  get "/services" do
    entries = Pulse.Monitor.list_services()

    body =
      Enum.map(entries, fn %Pulse.Monitor.Entry{service: s, latency_ms: latency_ms} ->
        %{
          id: s.id,
          name: s.name,
          url: s.url,
          latency_ms: latency_ms
        }
      end)
      |> Jason.encode!()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
