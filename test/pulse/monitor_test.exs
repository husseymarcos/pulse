defmodule Pulse.MonitorTest do
  use ExUnit.Case, async: false

  describe "monitoring services" do
    test "adding a service makes it appear in the list of monitored services" do
      service = %Pulse.Service{name: "Added", url: "https://example.com/added"}
      assert :ok == Pulse.Monitor.add_service(service)

      entries = Pulse.Monitor.list_services()
      entry = Enum.find(entries, fn e -> e.service.url == "https://example.com/added" end)
      assert entry != nil
      assert entry.service.name == "Added"
      assert entry.service.url == "https://example.com/added"
      assert is_integer(entry.service.id)
      assert Map.has_key?(entry, :latency_ms)

      Pulse.Monitor.remove_service(entry.service.id)
    end

    test "adding a service with a url already monitored returns already_exists" do
      url = "https://example.com/dup"
      service = %Pulse.Service{name: "Dup", url: url}
      assert :ok == Pulse.Monitor.add_service(service)
      assert {:error, :already_exists} == Pulse.Monitor.add_service(service)
      [entry] = Pulse.Monitor.list_services()
      Pulse.Monitor.remove_service(entry.service.id)
    end

    test "removing a service by id removes it from the list" do
      url = "https://example.com/gone"
      service = %Pulse.Service{name: "Gone", url: url}
      assert :ok == Pulse.Monitor.add_service(service)
      [entry] = Pulse.Monitor.list_services()
      id = entry.service.id
      assert Enum.any?(Pulse.Monitor.list_services(), fn e -> e.service.url == url end)

      assert :ok == Pulse.Monitor.remove_service(id)
      refute Enum.any?(Pulse.Monitor.list_services(), fn e -> e.service.url == url end)
    end

    test "removing by unknown id returns not_found" do
      assert {:error, :not_found} == Pulse.Monitor.remove_service(0)
    end

    test "check with known id returns ok, with unknown id returns not_found" do
      url = "https://example.com/checkable"
      service = %Pulse.Service{name: "Checkable", url: url}
      assert :ok == Pulse.Monitor.add_service(service)
      [entry] = Pulse.Monitor.list_services()
      id = entry.service.id
      assert :ok == Pulse.Monitor.check(id)
      assert :not_found == Pulse.Monitor.check(0)
      Pulse.Monitor.remove_service(id)
    end
  end
end
