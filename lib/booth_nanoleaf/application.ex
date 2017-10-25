defmodule BoothNanoleaf.Application do
  use Application
  require Logger
  alias Nerves.UART, as: Serial

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Serial.enumerate |> Enum.each(fn({tty, device}) ->
      Logger.info("#{inspect device}")
    end)
    children = [
      worker(BoothNanoleaf.Network, []),
      worker(BoothNanoleaf.TweetConsumer, []),
      worker(BoothNanoleaf.Twitter, []),
      worker(BoothNanoleaf.CO2, []),

    ]

    opts = [strategy: :one_for_one, name: BoothNanoleaf.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
