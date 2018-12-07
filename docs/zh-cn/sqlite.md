# SQLite
SQLite 是 C 写的轻量级数据库，它的数据库就是一个文件；在 SQLite 中，表是存放数据的集合，一个库中通常包含多个表

使用 SQLite 时，首先要连接到数据库，一个数据库连接是一个 `Connection`

`Connection` 每执行一条语句都会先将它**预编译**为 `Statement`；然后将变量参数插入之后再执行，因此如果我们有重复执行的动作，可以将编译好的 `Statement` 缓存起来，之后只需要将新的参数插入，可以提高执行的效率

执行 SQL 的 CRUD 语句后，需要打开游标 `Cursor`；然后通过 `Cursor` 访问执行的结果；从某些层面来说，游标就是一个**指向数据库中查询到的某一条数据的指针**

HQSqlite 就是针对以上操作的封装，对于每次执行的 SQL 语句做了一些缓存优化，同时提供了一些数据获取的语法糖

## Connection

### 初始化
`init(_ type: Location = .memory, readOnly: Bool = false)`

SQLite 可以初始化在内存中或者磁盘上，因此在初始化方法中提供了三种连接方式：
* `memory`  存储在内存中
* `temporary`  存储为临时文件，使用后会自动删除
* `uri(file)`  存储在指定的文件中

### 预编译
`func prepare(_ statement: String, _ bindings: SqliteMapping?...)`

传入要执行的 SQL 语句及变量，编译为 Statement 后返回；实质是调用 [Statement]() 中的方法

### 执行
`func run(_ statement: String, _ bindings: SqliteMapping?...)`

传入要执行的 SQL 语句及变量，编译并执行后返回 `Statement`

### 繁忙处理
* `var busyTimeout: Double = 0` 设置繁忙的时限，单位是 `ms`
* `func busyHandler(_ callback: ((_ tries: Int) -> Bool)?)` 繁忙时的回调，根据回调的返回值确定是否继续重试

### 追踪
`func trace(_ callback: ((String) -> Void)?)` 

追踪 `Statement` 每次执行后的回调

### 事务
* `func transaction(_ mode: TransactionMode = .deferred, block: () throws -> Void)`  修改事务的模式
* `func savepoint(_ name: String = UUID().uuidString, block: () throws -> Void)`  设置 `savepoint`
* `func transaction(_ begin: String, _ block: () throws -> Void, _ commit: String, or rollback: String)`  执行一条 SQL 语句并尝试提交事务，如果失败会自动 `rollback`

### 钩子
#### CRUD
`func updateHook(_ callback: ((_ operation: SqliteOperation, _ db: String, _ table: String, _ rowid: Int64) -> Void)?)`

注册一个钩子监听数据库插入、更新、删除

#### 事务提交
` func commitHook(_ callback: (() throws -> Void)?)`

注册监听事物提交成功

#### 事务回滚
`func rollbackHook(_ callback: (() -> Void)?)`

注册监听事务回滚

## Statement
`Statement` 初始化时就会编译好对应的 SQL 语句，同时 `Statement` 必须有对应的 `Connection`； 因此不提供初始化方法，只提供额外的绑定参数和执行语句的方法，`Statement` 需要通过 `Connection` 的预编译或执行方法获取

### 绑定
`func bind(_ values: SqliteMapping?...)` 

将新的变量绑定到已编译好的 `Statement` 上

### 执行
`public func run(_ bindings: SqliteMapping?...)`

将变量绑定到 `Statement` 并执行

`func step() throws -> Bool`

执行现有的参数绑定的 `Statement` 

### 重置
`func reset(_ clearBindings: Bool = true)`

将 `Statement` [重置](https://www.sqlite.org/c3ref/reset.html)到 prepare 的状态，同时可以选择是否清空已绑定的参数

## Cursor
SQLite 每次执行的结果都对应一个 `Cursor`，`Cursor` 对应 `Statement` 的执行结果，因此也不提供初始化的接口，可以通过 `Statement` 的属性获取

每个 `Cursor` 实质上是指向一条查询结果的指针；SQLite 的查询结果通常是通过*索引*访问的，因此封装了 `subscript` 方法来简化访问过程，同时提供迭代方法

