defmodule BoothNanoleaf.TweetConsumer do
  use GenStage
  require Logger

  @window 10 * 60_000
  @num_windows 6

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Process.send_after(self(), :window, @window)
    windows = 1..@num_windows |> Enum.map(fn(l) -> 0 end)
    {:consumer, %{windows: windows, current: 0}}
  end

  def handle_info(:window, state) do
    Logger.error("#{inspect state}")
    windows =
      case state.windows |> Enum.count do
        tot when tot >= @num_windows -> state.windows |> Enum.drop(-1)
        _ -> state.windows
      end
    windows = [state.current] ++ windows
    #render windows
    Process.send_after(self(), :window, @window)
    {:noreply, [], %{state | windows: windows, current: 0}}
  end

  def handle_events(events, _from, state) do
    events |> Enum.each(fn(tweet) ->
      Logger.info("#{inspect tweet["text"]}")
      #flash for new tweet
    end)
    {:noreply, [], %{state | current: state.current + (events |> Enum.count)}}
  end
end

defmodule BoothNanoleaf.Twitter do
  use GenServer
  require Logger

  @filter System.get_env("TWITTER_HASHTAG")

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Process.send_after(self(), :check_network, 500)
    {:ok, %{}}
  end

  def handle_info(:check_network, state) do
    case BoothNanoleaf.Network.connected? do
      true -> Process.send_after(self(), :start, 0)
      false -> Process.send_after(self(), :check_network, 500)
    end
    {:noreply, state}
  end

  def handle_info(:start, state) do
    Logger.info "Streaming: #{inspect @filter}"
    {:ok, stream} = Twittex.stream(@filter, [min_demand: 1, max_demand: 10, stage: true])
    {:ok, tag} = GenStage.sync_subscribe(BoothNanoleaf.TweetConsumer, to: stream)
    {:noreply, state}
  end
end
