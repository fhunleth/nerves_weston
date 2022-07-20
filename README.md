# NervesWeston

Launch Weston on Nerves

## Usage

```elixir
config_file = Application.app_dir(:your_app, "priv/weston.ini")

{NervesWeston, tty: 1, config_file: config_file, name: :weston]
```

## Installation

Include `nerves_weston` in your dependencies referencing `github`:

```elixir
def deps do
  [
    {:nerves_weston, github: "coop/nerves_weston"}
  ]
end
```
