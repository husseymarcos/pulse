defmodule Pulse.Web do
  @moduledoc """
  HTTP API for the TUI and other clients.

  GET /health   — health check (JSON: {"status":"ok"}).
  GET /services — list monitored services (JSON: id, name, url, latency_ms).
  POST /services — add a service (JSON body: name, url). Returns 201 or error.
  """

  use Plug.Router

  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  get "/health" do
    require Logger
    Logger.info("GET /health")
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

  post "/services" do
    case conn.body_params do
      %{"name" => name, "url" => url} when is_binary(name) and is_binary(url) ->
        name = String.trim(name)
        url = String.trim(url)

        if name == "" or url == "" do
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{error: "name and url are required"}))
        else
          case Pulse.Monitor.add_service(%Pulse.Service{name: name, url: url}) do
            :ok ->
              entries = Pulse.Monitor.list_services()
              created = Enum.find(entries, fn %Pulse.Monitor.Entry{service: s} -> s.url == url end)

              body =
                case created do
                  %Pulse.Monitor.Entry{service: s, latency_ms: latency_ms} ->
                    Jason.encode!(%{
                      id: s.id,
                      name: s.name,
                      url: s.url,
                      latency_ms: latency_ms
                    })

                  nil ->
                    Jason.encode!(%{status: "created"})
                end

              conn
              |> put_resp_content_type("application/json")
              |> send_resp(201, body)

            {:error, :already_exists} ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(409, Jason.encode!(%{error: "service with this URL already exists"}))

            {:error, _reason} ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(500, Jason.encode!(%{error: "failed to add service"}))
          end
        end

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "body must include name and url (strings)"}))
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
