defmodule User do
  use Ecto.Schema

  schema "users" do
    field(:full_name, :string)
    field(:email, :string)
    field(:avatar_url, :string)
    field(:confirmed_at, :naive_datetime)

    # embeds_one :profile, Profile do
    #   field(:online, :boolean)
    #   field(:dark_mode, :boolean)
    #   field(:visibility, Ecto.Enum, values: [:public, :private, :friends_only])
    # end
    # kita refactor dengan memanggil user_profile.ex

    embeds_one :profile, UserProfile

    timestamps()
  end

  def changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:full_name, :email])
    |> cast_embed(:profile, required: true, with: &profile_changeset/2)
  end

  def profile_changeset(profile, attrs \\ %{}) do
    profile
    |> cast(attrs, [:online, :dark_mode, :visibility])
    |> validate_required([:online, :visibility])
  end
end
