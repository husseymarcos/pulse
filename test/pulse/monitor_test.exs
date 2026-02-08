defmodule Pulse.MonitorTest do
  use ExUnit.Case, async: false

  @client_id "test-client"

  describe "monitoring services" do
    test "adding a service makes it appear in the list of monitored services" do
      service = %Pulse.Service{name: "Added", url: "https://example.com/added"}
      assert {:ok, _} = Pulse.Monitor.add_service(@client_id, service)

      services = Pulse.Monitor.list_services(@client_id)
      service = Enum.find(services, fn s -> s.url == "https://example.com/added" end)
      assert service != nil
      assert service.name == "Added"
      assert service.url == "https://example.com/added"
      assert is_integer(service.id)
      assert Map.has_key?(service, :latency_ms)

      Pulse.Monitor.remove_service(@client_id, service.id)
    end

    test "adding a service with a url already monitored returns already_exists" do
      url = "https://example.com/dup"
      service = %Pulse.Service{name: "Dup", url: url}
      assert {:ok, _} = Pulse.Monitor.add_service(@client_id, service)
      assert {:error, :already_exists} = Pulse.Monitor.add_service(@client_id, service)
      [service] = Pulse.Monitor.list_services(@client_id)
      Pulse.Monitor.remove_service(@client_id, service.id)
    end

    test "removing a service by id removes it from the list" do
      url = "https://example.com/gone"
      service = %Pulse.Service{name: "Gone", url: url}
      assert {:ok, _} = Pulse.Monitor.add_service(@client_id, service)
      [service] = Pulse.Monitor.list_services(@client_id)
      id = service.id
      assert Enum.any?(Pulse.Monitor.list_services(@client_id), fn s -> s.url == url end)

      assert :ok = Pulse.Monitor.remove_service(@client_id, id)
      refute Enum.any?(Pulse.Monitor.list_services(@client_id), fn s -> s.url == url end)
    end

    test "removing by unknown id returns not_found" do
      assert {:error, :not_found} = Pulse.Monitor.remove_service(@client_id, 0)
    end

    test "check with known id returns ok, with unknown id returns not_found" do
      url = "https://example.com/checkable"
      service = %Pulse.Service{name: "Checkable", url: url}
      assert {:ok, _} = Pulse.Monitor.add_service(@client_id, service)
      [service] = Pulse.Monitor.list_services(@client_id)
      id = service.id
      assert :ok = Pulse.Monitor.check(@client_id, id)
      assert :not_found = Pulse.Monitor.check(@client_id, 0)
      Pulse.Monitor.remove_service(@client_id, id)
    end
  end
end
