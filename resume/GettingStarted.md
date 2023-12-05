##Getting Started##

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