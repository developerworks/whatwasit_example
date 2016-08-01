# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :whatwasit_example,
  ecto_repos: [WhatwasitExample.Repo]

# Configures the endpoint
config :whatwasit_example, WhatwasitExample.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "upWg/uZW1d3QUl8dj/rlfk8TQhgywWS5r6nsKgGQWAI+FYS6llgPGM14l5MUTEGa",
  render_errors: [view: WhatwasitExample.ErrorView, accepts: ~w(html json)],
  pubsub: [name: WhatwasitExample.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# %% Coherence Configuration %%   Don't remove this line
config :coherence,
  user_schema: WhatwasitExample.User,
  repo: WhatwasitExample.Repo,
  module: WhatwasitExample,
  logged_out_url: "/",
  email_from: {"Your Name", "yourname@example.com"},
  opts: [:authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :invitable, :registerable]

config :coherence, WhatwasitExample.Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "your api key here"
# %% End Coherence Configuration %%
