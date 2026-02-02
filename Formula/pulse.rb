# typed: false
# frozen_string_literal: true

class Pulse < Formula
  desc "Service monitoring: HTTP health checks and a TUI to add and view services"
  homepage "https://github.com/husseymarcos/pulse"
  url "https://github.com/husseymarcos/pulse/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "" # replace with actual sha after first release
  license "MIT"
  head "https://github.com/husseymarcos/pulse.git", branch: "main"

  depends_on "elixir" => :build
  depends_on "go" => :build

  def install
    # Build Elixir release (includes ERTS; no runtime dep on erlang)
    system "mix", "local.hex", "--force"
    system "mix", "local.rebar", "--force"
    system "mix", "deps.get"
    system "MIX_ENV=prod", "mix", "release", "pulse"

    # Install release tree so libexec/pulse/bin/pulse and lib/ exist
    release_dir = buildpath/"_build/prod/rel/pulse"
    libexec.install release_dir

    # Build Go TUI with path to the release (libexec/pulse) and version
    release_path = libexec/"pulse"
    ldflags = %W[-s -w -X main.releaseDir=#{release_path} -X main.version=#{version}]
    system "go", "build", "-ldflags", ldflags.join(" "), "-o", "pulse-tui", "."

    # Single entrypoint: the Go binary (starts release + TUI)
    bin.install "pulse-tui" => "pulse"
  end

  test do
    out = shell_output("#{bin}/pulse -version")
    assert_match(/^pulse /, out)
  end
end
