defmodule NervesWeston do
  use Supervisor

  @tty 1
  @xdg_runtime_dir "/tmp/nerves_weston"

  def start_link(opts) do
    name = opts[:name] || raise ArgumentError, "the :name option is required"

    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl Supervisor
  def init(opts) do
    tty = opts[:tty] || @tty
    extra_args = opts[:extra_args] || []
    xdg_runtime_dir = opts[:xdg_runtime_dir] || @xdg_runtime_dir
    args = ["--tty=#{tty}"] ++ maybe_add_config_file(opts[:config_file]) ++ extra_args
    env = [{"XDG_RUNTIME_DIR", xdg_runtime_dir}]

    setup_xdg_runtime_dir(xdg_runtime_dir)
    setup_udev()

    children = [
      {MuonTrap.Daemon, ["weston", args, [env: env]]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp maybe_add_config_file(nil), do: []
  defp maybe_add_config_file(path), do: ["--config=#{path}"]

  defp setup_xdg_runtime_dir(path) do
    File.mkdir(path)
    stat = File.stat!(path)
    File.write_stat!(path, %{stat | mode: 33216})
  end

  # NOTE: One of these _require_ plugging in a device - that should be
  # configurable.
  defp setup_udev do
    :os.cmd('udevd -d')
    :os.cmd('udevadm trigger --type=subsystems --action=add')
    :os.cmd('udevadm trigger --type=devices --action=add')
    :os.cmd('udevadm settle --timeout=30')
  end
end
