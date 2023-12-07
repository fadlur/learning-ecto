## Getting Started

**Menambahkan Ecto ke aplikasi**

Kita generate dulu aplikasi Elixir baru dengan command berikut:

```elixir
mix new friends --sup
```

`--sup` option buat memastikan bahwa aplikasi ini mempunyai sebuah supervision tree, yang mana kita akan menambahkan Ecto nantinya.

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

> Kalau masih error, periksa lagi konfigurasi yang kita buat sebelumnya.

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

**Memasukkan data**

Kita dapat mengisi data baru ke table `people` dengan kode ini:

```elixir
person = %Friends.Person{}
Friends.Person.insert(person)
```

Kita bisa memasukkan data baru ke table `people` dengan kode ini:

```elixir
person = %Friends.Person{}
Friends.Repo.insert(person)
```

Untuk memasukkan data ke database kita, kita memanggil `insert` di `Friends.Repo`. yang merupakan modul yang digunakan untuk berbicara ke database kita. Fungsi ini memberi tahu Ecto bahwa kita ingin menyisipkan `Friends.Person` baru ke database sesuai dengan `Friends.Repo`. Struct `person` di sini mewakili data yang ingin kita masukkan ke database.

Penyisipan yang berhasil akan mengembalikan sebuah tuple, seperti ini:

```elixir
{:ok,
 %Friends.Person{__meta__: #Ecto.Schema.Metadata<:loaded, "people">, age: nil,
  first_name: nil, id: 1, last_name: nil}}
```

atom `:ok` dapat digunakan untuk _patter matching_ yang ditujukan untuk memastikan bahwa penyisipan data sukses. Situasi di mana penyisipan data kemungkinan tidak berhasil adalah jika anda memiliki batasan pada database itu sendiri. Sebagai contoh jika database memiliki batasan unique pada field dengan nama `field` maka sebuah email hanya dapat digunakan oleh satu orang, selanjutnya penyisipan akan gagal.

Kamu mungkin ingin _pattern match_ ke tuple untuk merujuk ke record yang dimasukkan ke dalam database:

```elixir
{:ok, person} = Friends.Repo.insert person
```

**Validating changes**

Di Ecto, kamu mungkin ingin mevalidasi perubahan sebelum mereka masuk ke database. Sebagai contoh, kamu mungkin ingin bahwa 1 person harus memiliki first_name dan last_name sebelum sebuah record dapat dimasukkan ke dalam database. Untuk ini, Ecto memiliki `changesets`.

Mari tambahkan sebuah changeset ke modul `Friends.Person` di dalam `lib/friends/person.ex` sekarang:

```elixir
def changeset(person, params \\ %{}) do
  person
  |> Ecto.changeset.cast(params, [:first_name, :last_name, :age])
  |> Ecto.changeset.validate_required([:first_name, :last_name])
end
```

Changeset ini membawa sebuah `person` dan sebuah set params, yang akan menjadi perubahan yang akan diterapkan ke `person` ini. fungsi pertama di `changeset` adalah casts yang mempunyai keys (kunci) `first_name`, `last_name` dan `age` dari parameter yang diteruskan ke dalam changeset. Casting memberi tahu changeset parameter apa yang diijinkan untuk diteruskan melewati changeset ini, dan apapun yang tidak ada di list akan diabaikan.

Di baris selanjutnya, kita memanggil `validate_required` yang mengatakan bahwa, untuk changeset ini, kita mengharapkan `first_name` dan `last_name` harus memiliki nilai yang spesifik. Mari kita gunakan changeset ini untuk membuat record baru tanpa `first_name` dan `last_name`:

```elixir
person = %Friends.Person{}
changeset = %Friends.Person.changeset(person, %{})
Friends.Repo.insert(changeset)
```

Di baris pertama, kita mengambil sebuah struct dari modul `Friends.Person`. Kita tahu apa fungsinya, karena kita melihatnya belum lama ini. di baris kedua, kita membuat sesuatu yang baru: kita mendefinisikan sebuah changeset. Changeset ini mengatakan
bahwa pada object `person` yang ditentukan, kita ingin membuat beberapa perubahan. Dalam hal ini, kita tidak ingin mengubah apapun.

Di baris terakhir, alih-alih kita memasukkan `person`, kita memasukkan `changeset`. Changeset tahu tenant `person`, perubahannya dan aturan validasi yang harus dipenuhi sebelum data dapat dimasukkan ke dalam database. Ketika baris ketiga ini berjalan, kita akan melihat ini:

```elixir
{:error,
 #Ecto.Changeset<
   action: :insert,
   changes: %{},
   errors: [
     first_name: {"can't be blank", [validation: :required]},
     last_name: {"can't be blank", [validation: :required]}
   ],
   data: #Friends.Person<>,
   valid?: false
 >}
```

Seperti terakhir kali kita melakukan penyisipan, ini mengembalikan sebuah tuple. Namun kali ini, elemen pertama di tuple ini adalah :error, yang mengindikasikan sesuatu yang salah terjadi. Informasi spesifik tentang apa yang terjadi disertakan dalam changeset yang dikembalikan. Kita dapat mengakses ini dengan melakukan _patter matching_:

```elixir
{:error, changeset} = Friends.Repo.insert(changeset)
```

Kemudian kita dapat mengakses errors dengan melakukan `changeset.errors`:

```elixir
[first_name: {"can't be blank", [validation: :required]}, last_name: {"can't be blank", [validation: :required]}]
```

Dan kita dapat meminta changeset sendiri jika tidak valid, bahkan sebelum melakukan apapun di penyisipan:

```elixir
changeset.valid?
#=> false
```

Sejak changeset ini memiliki errors, tidak ada record yang dimasukkan ke dalam table `people`.

Mari kita coba sekarang dengan data valid.

```elixir
person = %Friends.Person{}
changeset = Friends.Person.changeset(person, %{first_name: "fadlur", last_name: "rohman"})
Friends.Repo.insert(changeset)
```

responnya:

```elixir
{:ok,
 %Friends.Person{
   __meta__: #Ecto.Schema.Metadata<:loaded, "people">,
   id: 2,
   first_name: "fadlur",
   last_name: "rohman",
   age: nil
 }}
```

Karena `Friends.Repo.insert` mengembalikan sebuah tuple, kita dapat menggunakan sebuah `case` untuk menentukan code path berbeda tergantung apa yang terjadi:

```elixir
case Friends.Repo.insert(changeset) do
  {:ok, person} ->
    # do something with person
  {:error, changeset} ->
    # do something with changeset
```

Jika penyisipan changeset berhasil, kemudian kamu dapat melakukan apapun yang kamu inginkan terhadap `person` yang dikembalikan di dalam hasil. Jika gagal, kemudian kamu mempunyai akses ke changeset dan errornya. Di dalam kasus failur (gagal), kamu mungkin ingin menyajikan error ini ke user. Error di dalam changset adalah sebuah _keyword list_ yang terlihat seperti ini:

```elixir
[first_name: {"can't be blank", [validation: :required]},
 last_name: {"can't be blank", [validation: :required]}]
```

Elemen pertama dari tuple adalah pesan validasi, dan elemen kedua adalah sebuah _keyword list_ dari pilihan untuk pesan validasi. Bayangkan bahwa kita mempunyai sebuah field dengan nama `bio` yang kita validasi, dan field itu harus lebih panjang dari 15 karakter. Ini kira-kira yang akan dikembalikan:

```elixir
[first_name: {"can't be blank", [validation: :required]},
 last_name: {"can't be blank", [validation: :required]},
 bio: {"should be at least %{count} character(s)", [count: 15, validation: :length, kind: :min, type: :string]}]
```

Untuk menampilkan pesan error yang lebih _human friendly_, kita bisa menggunakan `Ecto.Changeset.traverse_errors/2`:

```elixir
traverse_errors(changeset, fn {msg, opts} ->
  Enum.reduce(opts, msg, fn {key, value}, acc ->
    String.replace(acc, "%{#{key}}", to_string(value))
  end)
end)
```

Ini akan mengambalikan hasil untuk erros yang ditampilkan di atas:

```elixir
%{
  first_name: ["can't be blank"],
  last_name: ["can't be blank"],
  bio: ["should be at least 15 character(s)"],
}
```

Satu lagi hal yang disebutkan di sini: kamu dapat mentrigger sebuah pengecualian (exception) dengan menggunakan `Friends.Repo.insert!/2`. Jika changeset invalid, kamu akan melihat exception `Ecto.InvalidChangesetError`. Di sini contoh sederhananya:

```elixir
Friends.Repo.insert! Friends.Person.changeset(%Friends.Person{}, %{first_name: "Ryan"})

** (Ecto.InvalidChangesetError) could not perform insert because changeset is invalid.

Errors

    %{last_name: [{"can't be blank", [validation: :required]}]}

Applied changes

    %{first_name: "Ryan"}

Params

    %{"first_name" => "Ryan"}

Changeset

    #Ecto.Changeset<
      action: :insert,
      changes: %{first_name: "Ryan"},
      errors: [last_name: {"can't be blank", [validation: :required]}],
      data: #Friends.Person<>,
      valid?: false
    >

   (ecto) lib/ecto/repo/schema.ex:257: Ecto.Repo.Schema.insert!/4
```

Pengecualian ini memperlihatkan kita perubahan dari changeset, dan bagaimana changeset ini invalid. Ini bisa sangat berguna jika kita ingin memasukkan banyak data dan kemudian mempunyai mempunyai sebuah exception jika data tidak dapat dimasukkan sama sekali.

Untuk penyisipan datanya sampai di sini, sekarang kita akan mengambil datanya.

**Query pertama**
