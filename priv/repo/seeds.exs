# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     WhatwasitExample.Repo.insert!(%WhatwasitExample.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
WhatwasitExample.Repo.delete_all WhatwasitExample.User

WhatwasitExample.User.changeset(%WhatwasitExample.User{}, %{name: "Test User", email: "testuser@example.com", password: "secret", password_confirmation: "secret"})
|> WhatwasitExample.Repo.insert!
