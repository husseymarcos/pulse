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
    Logger.info("GET /health")
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"status":"ok"}))
  end

  get "/services" do
    services = Pulse.Monitor.list_services()
    Logger.info("GET /services - returning #{length(services)} service(s)")

    body = Jason.encode!(services)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  post "/services" do
    Logger.info("POST /services")

    case conn.body_params do
      %{"name" => name, "url" => url} when is_binary(name) and is_binary(url) ->
        name = String.trim(name)
        url = String.trim(url)

        if name == "" or url == "" do
          Logger.warning("POST /services - empty name or url")
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{error: "name and url are required"}))
        else
          case Pulse.Monitor.add_service(%Pulse.Service{name: name, url: url}) do
            :ok ->
              Logger.info("POST /services - added service: #{name} (#{url})")
              services = Pulse.Monitor.list_services()
              created = Enum.find(services, fn %Pulse.Service{} = s -> s.url == url end)

              if created do
                Pulse.Monitor.check(created.service.id)
              end

              body =
                case created do
                  %Pulse.Service{} = service ->
                    Jason.encode!(service)

                  nil ->
                    Jason.encode!(%{status: "created"})
                end

              conn
              |> put_resp_content_type("application/json")
              |> send_resp(201, body)

            {:error, :already_exists} ->
              Logger.warning("POST /services - service already exists: #{url}")
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(409, Jason.encode!(%{error: "service with this URL already exists"}))

            {:error, _reason} ->
              Logger.error("POST /services - failed to add service: #{name} (#{url})")
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(500, Jason.encode!(%{error: "failed to add service"}))
          end
        end

      _ ->
        Logger.warning("POST /services - invalid body params")
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "body must include name and url (strings)"}))
    end
  end

  match _ do
    Logger.warning("404 Not Found: #{conn.request_path}")
    send_resp(conn, 404, "Not Found")
  end
end
