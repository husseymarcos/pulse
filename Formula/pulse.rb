class Pulse < Formula
  desc "Service monitoring: HTTP health checks and a TUI to add and view services"
  homepage "https://github.com/husseymarcos/pulse"
  url "https://github.com/husseymarcos/pulse/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "5f5dc5939d232f994898a00e278ce3ad6eca488f4f9033253fdf048618f32146"
  license "MIT"
  head "https://github.com/husseymarcos/pulse.git", branch: "main"

  depends_on "erlang" => :build
  depends_on "elixir" => :build
  depends_on "go" => :build

  def install
    # Install Hex and Rebar in build directory (sandbox can't write to ~/.mix)
    ENV["MIX_HOME"] = "#{buildpath}/.mix"
    ENV["PATH"] = "#{buildpath}/.mix/bin:#{ENV["PATH"]}"
    system "mix", "local.hex", "--force"
    system "mix", "local.rebar", "--force"
    system "mix", "deps.get"
    system "MIX_ENV=prod", "mix", "release", "pulse"

    release_dir = buildpath/"_build/prod/rel/pulse"
    libexec.install release_dir

    release_path = libexec/"pulse"
    ldflags = %W[-s -w -X main.releaseDir=#{release_path} -X main.version=#{version}]
    system "go", "build", "-ldflags", ldflags.join(" "), "-o", "pulse-tui", "."

    bin.install "pulse-tui" => "pulse"
  end

  test do
    out = shell_output("#{bin}/pulse -version")
    assert_match(/^pulse /, out)
  end
end
