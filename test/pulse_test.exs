defmodule PulseTest do
  use ExUnit.Case
  doctest Pulse

  test "greets the world" do
    assert Pulse.hello() == :world
  end
end
