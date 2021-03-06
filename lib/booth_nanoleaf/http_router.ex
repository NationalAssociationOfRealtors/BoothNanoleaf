defmodule BoothNanoleaf.HTTPRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/co2" do
    template_dir = :code.priv_dir(:booth_nanoleaf)
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> Plug.Conn.send_file(200, "#{template_dir}/co2_display.html.eex")
  end

end
