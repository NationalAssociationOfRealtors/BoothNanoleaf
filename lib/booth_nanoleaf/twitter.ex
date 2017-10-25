defmodule BoothNanoleaf.TweetConsumer do
  use GenStage
  require Logger

  @panels [149, 30, 223, 64, 80, 152] # these are panel id's in order of rendering
  @nano :"uuid:472bf39d-c492-4349-b250-f48c9ba305b0" #update this with the UDN of your nanoleaf
  @api_key "vdUXdmCVHoQ1eXdRkcvIbe6UKz89zovu"
  @color_states [
    {255, 255, 255},
    {217, 228, 247},
    {184, 202, 235},
    {148, 175, 220},
    {115, 152, 216},
    {0, 71, 186}
  ]

  @window 10_000#10 * 60_000
  @num_windows 5

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Process.send_after(self(), :window, @window)
    windows = 1..@num_windows |> Enum.map(fn(l) -> 0 end)
    {:consumer, %{windows: windows, current: 0}}
  end

  def handle_subscribe(:producer, _opts, _from, state) do
    Nanoleaf.Device.set_api_key(@nano, @api_key)
    {:automatic, state}
  end

  def handle_info(:window, state) do
    Logger.error("#{inspect state}")
    windows =
      case state.windows |> Enum.count do
        tot when tot >= @num_windows -> state.windows |> Enum.drop(-1)
        _ -> state.windows
      end
    windows = [state.current] ++ windows
    Nanoleaf.Device.write(@nano, %{write: %{command: "display", version: "1.0", animType: "custom", animData: render_windows(state), loop: false}})
    Process.send_after(self(), :window, @window)
    {:noreply, [], %{state | windows: windows, current: 0}}
  end

  def handle_events(events, _from, state) do
    events |> Enum.each(fn(tweet) ->
      Logger.info("#{__MODULE__}: #{tweet["text"]}")
      Nanoleaf.Device.write(@nano, %{write: %{command: "display", version: "1.0", animType: "custom", animData: flash(state), loop: false}})
    end)
    {:noreply, [], %{state | current: state.current + (events |> Enum.count)}}
  end

  def render_windows(state) do
    all = [state.current] ++ state.windows
    sorted = all |> Enum.sort
    0..5 |> Enum.reduce("6", fn(i, acc) ->
      v = all |> Enum.at(i)
      index = sorted |> Enum.find_index(fn i -> i == v end)
      {r, g, b} = @color_states |> Enum.at(index)
      id = @panels |> Enum.at(i)
      r = r
      g = g
      b = b
      "#{acc} #{id} 1 #{r} #{g} #{b} 1 20"
    end)
  end

  def flash(state) do
    all = [state.current] ++ state.windows
    sorted = all |> Enum.sort
    v = all |> Enum.at(0)
    index = sorted |> Enum.find_index(fn i -> i == v end)
    {r, g, b} = @color_states |> Enum.at(index)
    id = @panels |> Enum.at(0)
    "1 #{id} 3 0 71 186 1 2 255 255 255 0 2 #{r} #{g} #{b} 1 1"
  end

end

defmodule BoothNanoleaf.Twitter do
  use GenServer
  require Logger

  @filter "#worldseries"

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
    :timer.sleep(5000)
    {:ok, stream} = Twittex.stream(@filter, [min_demand: 1, max_demand: 10, stage: true])
    {:ok, tag} = GenStage.sync_subscribe(BoothNanoleaf.TweetConsumer, to: stream)
    {:noreply, state}
  end
end
