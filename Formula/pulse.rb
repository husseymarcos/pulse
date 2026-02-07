class Pulse < Formula
  desc "Service monitoring: HTTP health checks and a TUI to add and view services"
  homepage "https://github.com/husseymarcos/pulse"
  url "https://github.com/husseymarcos/pulse/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "5f5dc5939d232f994898a00e278ce3ad6eca488f4f9033253fdf048618f32146"
  license "MIT"
  head "https://github.com/husseymarcos/pulse.git", branch: "main"

  depends_on "elixir" => :build
  depends_on "erlang" => :build
  depends_on "go" => :build

  def install
    ENV["MIX_HOME"] = buildpath/".mix"
    ENV["HEX_HOME"] = buildpath/".hex"
    ENV["PATH"] = "#{ENV["MIX_HOME"]}/bin:#{ENV["HEX_HOME"]}/bin:#{ENV["PATH"]}"

    system "mix", "local.hex", "--force"
    system "mix", "local.rebar", "--force"
    system "mix", "deps.get"
    ENV["MIX_ENV"] = "prod"
    system "mix", "release", "pulse", "--overwrite", "--path", libexec

    ldflags = %W[
      -s -w
      -X main.releaseDir=#{libexec}
      -X main.version=#{version}
    ]
    system "go", "build", *ldflags, "-o", bin/"pulse", "."
  end

  test do
    assert_match "pulse #{version}", shell_output("#{bin}/pulse -version")
  end
end