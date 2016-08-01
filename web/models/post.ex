defmodule WhatwasitExample.Post do
  use WhatwasitExample.Web, :model
  use Whatwasit
  alias WhatwasitExample.Repo

  schema "posts" do
    field :title, :string
    field :body, :string

    timestamps
  end

  def getbypk(id) do
    Repo.get(__MODULE__, id)
  end

  def updatebypk(changeset, changes) when is_map(changes) do
    changeset = changeset |> Ecto.Changeset.change(changes)
    changeset |> Repo.update
  end

  def post_changeset(struct, params \\ %{}, opts \\ %{}) do
    # cast/3 把浏览器POST过来的数据强制转换为schema中定义的数据类型
    # validate_required/3 验证要求的字段, message选项为错误提示
    struct
    |> cast(params, [:title, :body])
    |> validate_required([:title, :body], [message: "标题和内容是必须的"])
    # |> prepare_version
    |> prepare_version(opts)
  end

  # def insert(map) do
  #   Map.merge(%__MODULE__{}, map) |> Repo.insert
  # end

  def insert(params) do
    changeset = post_changeset(%__MODULE__{}, params)
    if changeset.valid? do
      Repo.insert(changeset)
    else
      raise "Changeset is invalid."
    end
  end

  @doc """
  更新一条记录
  """
  def update(params) do
    # 从数据库获取一个 %WhatwasitExample.Post{} 结构
    struct = getbypk(params[:id])
    case struct do
      nil ->
        raise "Record not exists."
      struct ->
        fields = Map.delete(params, :id)
        # 通过浏览器传过来的POST数据创建一个Ecto.Changeset
        changeset = post_changeset(struct, fields)
        if changeset.valid? do
          changeset |> Repo.update
        else
          raise "Changeset is invalid when update."
        end
    end
  end

  @doc """
  按主键ID删除一条记录
  """
  @spec delete(map) :: Ecto.Schema.t | :no_return
  def delete(%{"id" => id}) do
    # 从数据库获取一个 %WhatwasitExample.Post{} 结构
    # 从 %WhatwasitExample.Post{} 创建一个 Ecto.Changeset
    # 把这个 Ecto.Changeset 传递给 Ecto.Repo.delete!/2
    Repo.get!(__MODULE__, id)
    |> __MODULE__.post_changeset
    |> Repo.delete!
  end
end
