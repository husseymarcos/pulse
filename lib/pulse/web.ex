defmodule Pulse.Web do
  @moduledoc """
  HTTP API for the TUI and other clients. Services are scoped by X-Client-ID (no login).
  If the client omits X-Client-ID, the server generates one and returns it in the response header.
  """

  use Plug.Router

  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:assign_client_id)
  plug(:match)
  plug(:dispatch)

  get "/health" do
    json(conn, 200, %{status: "ok"})
  end

  get "/services" do
    client_id = conn.assigns.client_id
    conn = maybe_put_client_id_header(conn)
    json(conn, 200, Pulse.Monitor.list_services(client_id))
  end

  post "/services" do
    client_id = conn.assigns.client_id
    conn = maybe_put_client_id_header(conn)

    case conn.body_params do
      %{"name" => name, "url" => url} when is_binary(name) and is_binary(url) ->
        name = String.trim(name)
        url = String.trim(url)
        if name == "" or url == "" do
          json(conn, 400, %{error: "name and url are required"})
        else
          add_service(conn, client_id, name, url)
        end

      _ ->
        json(conn, 400, %{error: "body must include name and url (strings)"})
    end
  end

  delete "/services/:id" do
    client_id = conn.assigns.client_id
    conn = maybe_put_client_id_header(conn)

    case Integer.parse(conn.path_params["id"]) do
      {id, ""} ->
        case Pulse.Monitor.remove_service(client_id, id) do
          :ok -> json(conn, 204, nil)
          {:error, :not_found} -> send_resp(conn, 404, "")
          _ -> json(conn, 500, %{error: "Failed to remove service"})
        end
      _ -> json(conn, 400, %{error: "Invalid service id"})
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp assign_client_id(conn, _opts) do
    raw = get_req_header(conn, "x-client-id") |> List.first()
    {client_id, new?} =
      if raw == nil or String.trim(raw || "") == "" do
        {Ecto.UUID.generate(), true}
      else
        {String.trim(raw), false}
      end

    conn
    |> assign(:client_id, client_id)
    |> assign(:new_client_id, new?)
  end

  defp maybe_put_client_id_header(conn) do
    if conn.assigns[:new_client_id] do
      put_resp_header(conn, "x-client-id", conn.assigns.client_id)
    else
      conn
    end
  end

  defp json(conn, status, body) do
    conn = maybe_put_client_id_header(conn)
    body_str = if body == nil, do: "", else: Jason.encode!(body)
    conn =
      if status != 204 do
        put_resp_content_type(conn, "application/json")
      else
        conn
      end
    send_resp(conn, status, body_str)
  end

  defp add_service(conn, client_id, name, url) do
    service = %Pulse.Service{name: name, url: url}
    case Pulse.Monitor.add_service(client_id, service) do
      {:ok, created} ->
        Pulse.Monitor.check(client_id, created.id)
        json(conn, 201, created)

      {:error, :already_exists} ->
        json(conn, 409, %{error: "Service with this URL already exists"})

      {:error, _} ->
        json(conn, 500, %{error: "Failed to add service"})
    end
  end
end
