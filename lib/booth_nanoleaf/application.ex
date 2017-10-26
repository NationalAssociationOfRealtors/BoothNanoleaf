defmodule BoothNanoleaf.Application do
  use Application
  require Logger
  alias Nerves.UART, as: Serial
  @http_port Application.get_env(:booth_nanoleaf, :http_port, 8080)

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
      Plug.Adapters.Cowboy.child_spec(:http, BoothNanoleaf.HTTPRouter, [], [port: @http_port, dispatch: dispatch]),
    ]

    opts = [strategy: :one_for_one, name: BoothNanoleaf.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_, [
        {"/ws", BoothNanoleaf.WebSocketHandler, []},
        {:_, Plug.Adapters.Cowboy.Handler, {BoothNanoleaf.HTTPRouter, []}}
      ]}
    ]
  end
end
