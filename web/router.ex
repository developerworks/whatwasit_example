defmodule WhatwasitExample.Router do
  use WhatwasitExample.Web, :router
  use Coherence.Router

  pipeline :public do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, login: true
  end

  scope "/" do
    pipe_through :public
    coherence_routes :public
  end

  scope "/" do
    pipe_through :browser
    coherence_routes :private
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WhatwasitExample do
    pipe_through :public

    get "/", PageController, :index
    # add public resource below
  end

  scope "/", WhatwasitExample do
    pipe_through :browser

    # add protected resources below
    resources "/posts", PostController
  end

  # Other scopes may use custom stacks.
  # scope "/api", WhatwasitExample do
  #   pipe_through :api
  # end
end
