## Getting Started

**Menambahkan Ecto ke aplikasi**

Kita generate dulu aplikasi Elixir baru dengan command berikut:

```elixir
mix new friends --sup
```

`
--sup
` option buat memastikan bahwa aplikasi ini mempunyai sebuah supervision tree, yang mana kita akan menambahkan Ecto nantinya.

Untuk menambahkan Ecto ke aplikasi ini, ada beberapa langkah. Langkah pertama kita akan menambahkan Ecto dan sebuah driver yang dipanggil Postgrex ke file `mix.exs`.
```elixir
defp deps do
  [
    {:ecto_sql, "~> 3.0"},
    {:postgrex, ">= 0.0.0"}
  ]
end
```

Ecto menyediakan API untuk query yang umum, tapi kita perlu menambahkan Postgrex driver, karena itu yang digunakan untuk berkomunikasi dengan PostgreSQL. Ecto berkomunikasi dengan module `Ecto.Adapters.Postgres` yang kemudian berkomunikasi ke paket `postgres`untuk berkomunikasi dengan PostgreSQL.

Untuk menginstall dependensi ini, kita akan menjalankan perintah berikut:

```elixir
mix deps.get
```

Aplikasi postgrex akan menerima query dari Ecto dan mengeksekusinya ke database kita. Jika kita tidak melakukan langkah ini, kita tidak dapat melakukan query apapun.

Langkah pertama sudah kita lakukan, langkah berikutnya kita perlu melakukan konfigurasi untuk Ecto supaya kita dapat menjalakan aksi ke sebuah database dari kode aplikasi kita.

Kita dapat mengatur konfigurasi dengan menjalankan perintah berikut:

```elixir
mix ecto.gen.repo -r Friends.Repo
```

Perintah ini akan mengenerate konfigurasi yang dibutuhkan untuk terhubung ke sebuah database. Konfigurasi pertama kita ada di dalam `config/config.exs`:

```elixir
config :friends, Friends.Repo,
  database: "friends",
  username: "user",
  password: "pass",
  hostname: "localhost"
```

Sesuaikan settingan dengan setting yang terpasang di PostgreSQL. Baik nama database, username, dan passwordnya.

Konfigurasi ini adalah bagaimana Ecto akan terhubung ke database kita dengan nama "friends". Secara khusus, itu mengkonfigurasi sebuah "repo".

modul `Friends.Repo` didefinisikan di dalam `lib/friends/repo.ex` oleh perintah `mix ecto.gen.repo`:

```elixir
defmodule Friends.Repo do
  use Ecto.Repo,
    otp_app: :friends,
    adapter: Ecto.Adapters.Postgres
end
```

Modul ini adalah apa yang akan kita gunakan untuk query ke database kita. Modul ini menggunakan modul `Ecto.Repo`, dan `otp_app` memberi tahu Ecto di aplikasi elixir mana dia dapat mencari konfigurasi database. Di kasus ini, kita sudah menetapkan bahwa aplikasi `:friends` di mana Ecto dapat menemukan konfigurasi itu dan selanjutnya Ecto akan menggunakan konfigurasi yang telah disetup di `config/config.exs`. Akhirnya kita mengkonfigurasi database `:adapter` ke Postgres.

Tahap terakhir konfigurasi adalah untuk mensetup `Friends.Repo` sebagai sebuah supervisor di dalam supervision tree aplikasi, yang dapat kita lakukan di dalam `lib/friends/application.ex`, di dalam fungsi `start/2`:

```elixir
def start(_type, _args) do
  children = [
    Friends.Repo,
  ]

  ...
```

Konfigurasi ini akan memulai Ecto process yang akan menerima dan mengeksekusi query aplikasi kita. Tanpa itu, kita tidak dapat melakukan query ke database sama sekali.

Ada satu lagi, terakhir ini. Konfigurasi ini harus kita tambahkan sendiri, karena generator tidak menambahkannya. Di dalam `config/config.exs`, tambahkan baris ini:

```elixir
config :friends, ecto_repos: [Friends.Repo]
```

Ini memberitahu aplikasi kita tentang repo yang akan mengijinkan kita untuk menjalankan perintah seperti `mix ecto.create`.

Konfigurasi sudah kita atur, sekarang saat membuat database.

**Mengatur database**

untuk menambahkan database, jalankan perintah berikut:

```elixir
mix ecto.create
```

Jika database berhasil dibuat, akan muncul pesan:

```elixir
The database for Friends.Repo has been created.
```

>Kalau masih error, periksa lagi konfigurasi yang kita buat sebelumnya.

Sebuah database sendiri tidak dapat diquery, jadi kita perlu membuat sebuah table di dalam database tersebut. Untuk melakukan itu kita akan menggunakan apa yang dinamakan _migration_. Jika pernah menggunakan Active Record (atau sejenisnya), pasti telah melihatnya sebelumnya. Sebuah migration adalah sebuah langkah di dalam proses membangun database.

Sekarang buat sebuah migration dengan perintah:

```elixir
mix ecto.gen.migration create_people
```

Perintah ini akan mengenerate sebuah migration baru di dalam folder `priv/repo/migrations`, saat ini masih kosong seperti ini:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do

  end
end
```

Tambahkan beberapa kode ke migration untuk membuat table baru dengan nama "people", dengan beberapa kolom di dalamnya:

```elixir
defmodule Friends.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :first_name, :string
      add :last_name, :string
      add :age, :integer
    end
  end
end
```

Kode ini memberi tahu Ecto untuk membuat table baru dengan nama `people`, dan menambahkan 3 field baru: `first_name`, `last_name`, dan `age` untuk table itu. Tipe untuk field itu adalah `string` dan `integer`.

**NOTE**: naming convention untuk table di database Ecto adalah menggunakan pluralized name (jamak).

Untuk menjalankan migration dan membuat table `people` di database kita, kita akan menjalankan perintah ini:

```elixir
mix ecto.migrate
```

Jika kita menemukan bahwa kita telah membuat kesalahan di dalam migration, kita dapat menjalankan perintah `mix ecto.rollback` untuk undo perubahan di dalam migration. Kita dapat memperbaiki perubahan di migration dan menjalankan `mix ecto.migrate` lagi. Jika kita menjalankan `mix ecto.rollback` sekarang, itu akan menghapus table yang telah kita buat.

Sekarang kita telah mempunyai table di dalam database. Selanjutnya kita akan membuat skema (the schema).

**Membuat Skema (schema)**

Skema adalah sebuah representasi Elixir dari data dari database kita. Skema umumnya diasosiasikan dengan sebuah table database, namun skema juga bisa diasosiasikan dengan tampilan database.

Mari kita buat skema di dalam aplikasi kita di `lib/friends/person.ex`:

```elixir
defmodule Friends.Person do

  use Ecto.Schema

  schema "people" do
    field :first_name, :string
    field :last_name, :string
    field :age, :integer
  end
end
```

Ini mendefinisikan skema dari database yang dipetakan oleh skema ini. Dalam kasus ini, kita memberitahu Ecto bahwa skema `Friends.Person` memetakan ke table `person` di dalam database, dan field `first_name`, `last_name` dan `age` di table itu. Argument kedua yang diteruskan ke `field` memberitahu Ecto bagaimana kita menginginkan informasi dari database direpresentasikan di dalam skema kita.

Kita memanggil skema dengan `Person` karena naming convention di Ecto untuk skema adalah sebuah singularized name.

Kita dapat bermain dengan skema ini di dalam sebuah `IEx session` dengan memulai `iex -S mix` kemudian jalankan kode ini:

```elixir
person = %Friends.Person{}
```

Kode ini akan memberi kita sebuah struct baru `Friends.Person`, yang memiliki nilai `nil` untuk semua field. Kita dapat mengatur nilai ke field ini dengan mengenerate struct baru (ini karena imutable di elixir):

```elixir
person = %Friends.Person{age: 18}
```

atau dengan syntax seperti ini:

```elixir
person = %{person | age: 18}
```

Kita dapat mengambil nilainya dengan menggunakan syntax berikut:

```elixir
person.age # => 18
```

Sekarang mari kita lihat bagaimana kita dapat mengisi data ke database.

**Mengisi data**

Kita dapat mengisi data baru ke table `people` dengan kode ini:

```elixir
person = %Friends.Person{}
Friends.Person.insert(person)
```

