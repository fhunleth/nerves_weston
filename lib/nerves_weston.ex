defmodule NervesWeston do
  use Supervisor

  @definition [
    name: [
      required: true,
      type: :atom
    ],
    tty: [
      required: true,
      type: :non_neg_integer
    ],
    xdg_runtime_dir: [
      required: true,
      type: :string
    ],
    cli_args: [
      required: false,
      type: {:list, :string},
      default: []
    ],
    daemon_opts: [
      type: :keyword_list,
      required: false,
      default: []
    ]
  ]
  @schema NimbleOptions.new!(@definition)

  def start_link(opts) do
    opts = NimbleOptions.validate!(opts, @schema)

    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl Supervisor
  def init(opts) do
    args = ["--continue-without-input" | opts[:cli_args]]
    env = [{"XDG_RUNTIME_DIR", opts[:xdg_runtime_dir]}]

    setup_xdg_runtime_dir(opts[:xdg_runtime_dir])
    setup_udev()

    children = [
      {MuonTrap.Daemon, ["weston", args, [{:env, env} | opts[:daemon_opts]]]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

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
