defmodule Pulse.MonitorTest do
  use ExUnit.Case, async: false

  describe "monitoring services" do
    test "adding a service makes it appear in the list of monitored services" do
      service = %Pulse.Service{id: :added, name: "Added", url: "https://example.com"}
      assert :ok == Pulse.Monitor.add_service(service)

      entries = Pulse.Monitor.list_services()
      entry = Enum.find(entries, fn e -> e.service.id == :added end)
      assert entry != nil
      assert entry.service.name == "Added"
      assert entry.service.url == "https://example.com"
      assert Map.has_key?(entry, :latency_ms)

      Pulse.Monitor.remove_service(:added)
    end

    test "adding a service with an id already monitored returns already_exists" do
      service = %Pulse.Service{id: :dup, name: "Dup", url: "https://example.com"}
      assert :ok == Pulse.Monitor.add_service(service)
      assert {:error, :already_exists} == Pulse.Monitor.add_service(service)
      Pulse.Monitor.remove_service(:dup)
    end

    test "removing a service by id removes it from the list" do
      service = %Pulse.Service{id: :gone, name: "Gone", url: "https://example.com"}
      assert :ok == Pulse.Monitor.add_service(service)
      assert Enum.any?(Pulse.Monitor.list_services(), fn e -> e.service.id == :gone end)

      assert :ok == Pulse.Monitor.remove_service(:gone)
      refute Enum.any?(Pulse.Monitor.list_services(), fn e -> e.service.id == :gone end)
    end

    test "removing by unknown id returns not_found" do
      assert {:error, :not_found} == Pulse.Monitor.remove_service(:nonexistent)
    end

    test "check with known id returns ok, with unknown id returns not_found" do
      service = %Pulse.Service{id: :checkable, name: "Checkable", url: "https://example.com"}
      assert :ok == Pulse.Monitor.add_service(service)
      assert :ok == Pulse.Monitor.check(:checkable)
      assert :not_found == Pulse.Monitor.check(:unknown_id)
      Pulse.Monitor.remove_service(:checkable)
    end
  end
end
