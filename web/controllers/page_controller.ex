defmodule WhatwasitExample.PageController do
  use WhatwasitExample.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
