defmodule WhatwasitExample.PostController do
  use WhatwasitExample.Web, :controller

  alias WhatwasitExample.Post


  # defp whodoneit(conn) do
  #   user = Coherence.current_user(conn)
  #   [whodoneit: user , whodoneit_name: user.name]
  # end

  defp whodoneit(conn) do
    # remove the password fields
    whodoneit = Coherence.current_user(conn)
    |> WhatwasitExample.Whatwasit.Version.remove_fields(~w(password password_confirmation password_hash)a)
    [whodoneit: whodoneit]
  end

  def index(conn, _params) do
    posts = Repo.all(Post)
    render(conn, "index.html", posts: posts)
  end

  def new(conn, _params) do
    changeset = Post.post_changeset(%Post{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"post" => post_params}) do
    changeset = Post.post_changeset(%Post{}, post_params)

    case Repo.insert(changeset) do
      {:ok, _post} ->
        conn
        |> put_flash(:info, "Post created successfully.")
        |> redirect(to: post_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    post = Repo.get!(Post, id)
    render(conn, "show.html", post: post)
  end

  def edit(conn, %{"id" => id}) do
    post = Repo.get!(Post, id)
    changeset = Post.post_changeset(post)
    render(conn, "edit.html", post: post, changeset: changeset)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Repo.get!(Post, id)
    changeset = Post.post_changeset(post, post_params, whodoneit(conn))

    case Repo.update(changeset) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> redirect(to: post_path(conn, :show, post))
      {:error, changeset} ->
        render(conn, "edit.html", post: post, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    changeset = Repo.get!(Post, id)
    |> Post.post_changeset(%{}, whodoneit(conn))

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(changeset)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: post_path(conn, :index))
  end
end
