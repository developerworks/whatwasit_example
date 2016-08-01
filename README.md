> [Whatwasit](https://github.com/smpallen99/whatwasit) 是一个跟踪Ecto模型变化的一个包, 用于审计和版本化. 审计在某些情况下是我们非常需要的, 比如我们需要知道谁在系统中修改了什么, 可以形成审计日志备后期进行审查.

> **注意**:  Whatwasit(读作: `What was it`) 需要Elixir 1.3的支持, 所以要使用 Whatwasit 请首先升级到Elixir 1.3

## 跟踪变化

使用 Whatwasit 很简单, 只需要添加在模型中添加两行代码即可, 下面我们来细说这个过程. 首先创建一个项目:

这里我们只是测试如何使用Whatwasit, 所以去掉前端库Brunch(`--no-brunch`).

```
mix phoenix.new whatwasit_example --no-brunch
```

在`mix.exs`中增加依赖:

```
defp deps do
  [
    ...
    {:whatwasit, "~> 0.2.1"}
  ]
end
```

切换到命令行执行

```
mix deps.get && mix compile
```

运行下面的用于创建存储版本和变更的模型和数据库迁移脚本

```
➜  whatwasit_example mix whatwasit.install
* creating priv/repo/migrations/20160801031533_create_whatwasit_version.exs
* creating web/models/whatwasit/version.ex
Add the following to your config/config.exs:

  config :whatwasit,
    repo: WhatwasitExample.Repo

Update your models like this:

  defmodule WhatwasitExample.Post do
    use WhatwasitExample.Web, :model
    use Whatwasit         # add this

    schema "posts" do
      field :title, :string
      field :body, :string
      timestamps
    end

    def changeset(model, params \ %{}) do
      model
      |> cast(params, ~w(title body))
      |> validate_required(~w(title body)a)
      |> prepare_version     # add this
    end
  end
```

执行数据库迁移脚本

```
mix ecto.migrate
```

命令行提示你在模块头部添加 `use Whatwasit`, 在`changeset/2` 方法的管道尾部添加 `prepare_version`函数追踪数据库的变更. 版本存储在 `versions` 表里面, 其结构如下:

![图片描述][1]

图中的 `object` 字段是一个JSON数据, 存储了修改之前的快照版本. `Whatwasit.Version` 模型的定义如下:

```elixir
schema "versions" do
  field :item_type, :string
  field :item_id, :integer
  field :action, :string  # ~w(update delete)
  field :object, :map     # versioned schema stored as a map

  timestamps
end
```

其对应的数据库迁移脚本如下:

```elixir
defmodule WhatwasitExample.Repo.Migrations.CreateWhatwasitVersion do
  use Ecto.Migration
  def change do
    create table(:versions) do
      add :item_type, :string, null: false
      add :item_id, :integer, null: false
      add :action, :string
      add :object, :map, null: false
      timestamps
    end

  end
end
```


下面是一个博客的示例

```elixir
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

  def user_changeset(struct, params \\ %{}) do
    # cast/3 把浏览器POST过来的数据强制转换为schema中定义的数据类型
    # validate_required/3 验证要求的字段, message选项为错误提示
    struct
    |> cast(params, [:title, :body])
    |> validate_required([:title, :body], [message: "标题和内容是必须的"])
    |> prepare_version
  end

  # def insert(map) do
  #   Map.merge(%__MODULE__{}, map) |> Repo.insert
  # end

  def insert(params) do
    changeset = user_changeset(%__MODULE__{}, params)
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
        changeset = user_changeset(struct, fields)
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
    |> __MODULE__.user_changeset
    |> Repo.delete!
  end
end

```

![图片描述][2]

## 跟踪谁修改了数据

首先需要添加 `{:coherence, "~> 0.2.0"}` 依赖, [Coherence](https://github.com/smpallen99/coherence) 是一个用户管理包, 提供了用户系统的常用功能, 包括:

- 注册, 注册新用户
- 邮件激活, 生成邮件激活链接通过邮件发送给用户
- 密码恢复, 生成密码找回连接通过邮件发送给用户
- 登录跟踪, 为每个保存了每次登录的时间, 次数, IP地址
- 锁定, 登录N次错误后自动锁定用户一段时间
- 解锁, 生成一个解锁连接通过邮件发送给用户

初始化 Coherence

```
mix coherence.install --full-invitable
```

上述命令会执行如下步骤:

- 添加 coherence 的配置到 `config/config.exs` 文件的尾部.
- 如果用户模型不存在, 添加新的用户模型
- 添加数据库迁移脚本文件
    + timestamp_add_coherence_to_user.exs 如果用户模型已经存在
    + timestamp_create_coherence_user.exs 如果用户模型不存在
    + timestamp_create_coherence_invitable.exs
在 `web/views/coherence/` 中添加相关的视图
在 `web/templates/coherence` 添加相关的模板
add email files to web/emails/coherence
添加 `web/coherence_web.ex` 文件

最后查看一下 `config/config.exs` 文件编辑电子邮件的Key, 这里你可以申请一个 [mailgun]的(https://www.mailgun.com/)邮件服务key用于测试.

完整的命令输出

```
➜ whatwasit_example# mix coherence.install --full-invitable
Your config/config.exs file was updated.
Compiling 14 files (.ex)
warning: unused import Ecto
  web/models/whatwasit/version.ex:7

Generated whatwasit_example app
* creating priv/repo/migrations/20160801060750_create_coherence_user.exs
* creating web/models/coherence/user.ex
* creating priv/repo/migrations/20160801060751_create_coherence_invitable.exs
* creating web/coherence_web.ex
* creating web/views/coherence/coherence_view.ex
* creating web/views/coherence/email_view.ex
* creating web/views/coherence/invitation_view.ex
* creating web/views/coherence/layout_view.ex
* creating web/views/coherence/coherence_view_helpers.ex
* creating web/views/coherence/password_view.ex
* creating web/views/coherence/registration_view.ex
* creating web/views/coherence/session_view.ex
* creating web/views/coherence/unlock_view.ex
* creating web/templates/coherence/email/confirmation.html.eex
* creating web/templates/coherence/email/invitation.html.eex
* creating web/templates/coherence/email/password.html.eex
* creating web/templates/coherence/email/unlock.html.eex
* creating web/templates/coherence/invitation/edit.html.eex
* creating web/templates/coherence/invitation/new.html.eex
* creating web/templates/coherence/layout/app.html.eex
* creating web/templates/coherence/layout/email.html.eex
* creating web/templates/coherence/password/edit.html.eex
* creating web/templates/coherence/password/new.html.eex
* creating web/templates/coherence/registration/new.html.eex
* creating web/templates/coherence/session/new.html.eex
* creating web/templates/coherence/unlock/new.html.eex
* creating web/emails/coherence/coherence_mailer.ex
* creating web/emails/coherence/user_email.ex

Add the following to your router.ex file.

defmodule WhatwasitExample.Router do
  use WhatwasitExample.Web, :router
  use Coherence.Router         # Add this

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, login: true  # Add this
  end

  pipeline :public do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session               # Add this
  end

  # Add this block
  scope "/" do
    pipe_through :public
    coherence_routes :public
  end

  # Add this block
  scope "/" do
    pipe_through :browser
    coherence_routes :private
  end

  scope "/", WhatwasitExample do
    pipe_through :public
    get "/", PageController, :index
  end

  scope "/", WhatwasitExample do
    pipe_through :browser
    # Add your protected routes here
  end
end


You might want to add the following to your priv/repo/seeds.exs file.

WhatwasitExample.Repo.delete_all WhatwasitExample.User

WhatwasitExample.User.changeset(%WhatwasitExample.User{}, %{name: "Test User", email: "testuser@example.com", password: "secret", password_confirmation: "secret"})
|> WhatwasitExample.Repo.insert!

Don't forget to run the new migrations and seeds with:
    $ mix ecto.setup
```

删除之前生成的数据库迁移脚本

```
rm priv/repo/migrations/20160801064451_create_whatwasit_version.exs
```

重新创建数据库

```
mix ecto.reset
```

`|> prepare_version` 修改为  `|> prepare_version(opts)`, 传入 `opts` 参数.

修改后的 Post 模型的 changeset 函数, 增加第三个参数 `opts`:

```elixir
def user_changeset(struct, params \\ %{}, opts \\ %{}) do
  # cast/3 把浏览器POST过来的数据强制转换为schema中定义的数据类型
  # validate_required/3 验证要求的字段, message选项为错误提示
  struct
  |> cast(params, [:title, :body])
  |> validate_required([:title, :body], [message: "标题和内容是必须的"])
  |> prepare_version(opts)
end
```

上面的多个手工步骤可以用 `mix phoenix.gen.html Post posts title:string body:string` 自动生成控制器, 视图, 模型, 模板文件. 然后修改, 可以少些很多代码.

上述步骤都完成后, 可以通过命令 `mix phoenix.routes` 查看所有的HTTP端点

```
➜  whatwasit_example mix phoenix.routes
     session_path  GET     /sessions/new            Coherence.SessionController :new
     session_path  POST    /sessions                Coherence.SessionController :create
registration_path  GET     /registrations/:id/edit  Coherence.RegistrationController :edit
registration_path  GET     /registrations/new       Coherence.RegistrationController :new
registration_path  POST    /registrations           Coherence.RegistrationController :create
registration_path  PATCH   /registrations/:id       Coherence.RegistrationController :update
                   PUT     /registrations/:id       Coherence.RegistrationController :update
registration_path  DELETE  /registrations/:id       Coherence.RegistrationController :delete
    password_path  GET     /passwords/:id/edit      Coherence.PasswordController :edit
    password_path  GET     /passwords/new           Coherence.PasswordController :new
    password_path  POST    /passwords               Coherence.PasswordController :create
    password_path  PATCH   /passwords/:id           Coherence.PasswordController :update
                   PUT     /passwords/:id           Coherence.PasswordController :update
    password_path  DELETE  /passwords/:id           Coherence.PasswordController :delete
      unlock_path  GET     /unlocks/:id/edit        Coherence.UnlockController :edit
      unlock_path  GET     /unlocks/new             Coherence.UnlockController :new
      unlock_path  POST    /unlocks                 Coherence.UnlockController :create
  invitation_path  GET     /invitations/:id/edit    Coherence.InvitationController :edit
  invitation_path  GET     /invitations/new         Coherence.InvitationController :new
  invitation_path  POST    /invitations             Coherence.InvitationController :create
  invitation_path  POST    /invitations/create      Coherence.InvitationController :create_user
  invitation_path  GET     /invitations/:id/resend  Coherence.InvitationController :resend
     session_path  DELETE  /sessions/:id            Coherence.SessionController :delete
        page_path  GET     /                        WhatwasitExample.PageController :index
        post_path  GET     /posts                   WhatwasitExample.PostController :index
        post_path  GET     /posts/:id/edit          WhatwasitExample.PostController :edit
        post_path  GET     /posts/new               WhatwasitExample.PostController :new
        post_path  GET     /posts/:id               WhatwasitExample.PostController :show
        post_path  POST    /posts                   WhatwasitExample.PostController :create
        post_path  PATCH   /posts/:id               WhatwasitExample.PostController :update
                   PUT     /posts/:id               WhatwasitExample.PostController :update
        post_path  DELETE  /posts/:id               WhatwasitExample.PostController :delete
```

这样一个基本的带用户注册, 密码找回, 用户激活, 等功能的应用程序的基本结构就完成了. 在此基础之上可以扩展功能实现更加完整的Web应用程序.

## 注意事项

- 目前模型里面的changeset需要重命名, `PROJECT_NAME.Whatwasit.Version`模块中的`changeset`函数和通过`mix phoenix.gen.html` 生成的模型中的`changeset` 函数名称冲突, 建议修改模型中的`changeset`函数为`post_changeset`

- `mix whatwasit.install --whodoneit-map` 和 `mix whatwasit.install --whodoneit`区别是, `mix whatwasit.install --whodoneit` 在versions表中用两个字段分别存储用户名称和用户ID, 这是对`users`表的引用, `mix whatwasit.install --whodoneit-map`, 用一个字段`whodoneit`存储的是一个除密码之外的用户所有信息的一个JSON对象. 后者不依赖于用户信息的变更.

- 如果用户模型的主键类型为UUID, 可以使用 `mix whatwasit.install --whodoneit-id-type=uuid`

最后我们在浏览器中输入  http://127.0.0.1:4000/posts/new 创建一条记录, 并编辑, 编辑的日志输出为.


![图片描述][3]

  [1]: https://segmentfault.com/img/bVzTQK
  [2]: https://segmentfault.com/img/bVzTCI
  [3]: https://segmentfault.com/img/bVzUwi
