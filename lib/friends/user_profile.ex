defmodule UserProfile do
  use Ecto.Schema

  embedded_schema do
    field(:online, :boolean)
    field(:dark_mode, :boolean)
    field(:visibility, Ecto.Enum, values: [:public, :private, :friends_only])
  end

  def changeset(%UserProfile{} = profile, attrs \\ %{}) do
    profile
    |> cast(attrs, [:online, :dark_mode, :visibility])
    |> validate_required([:online, :visibility])
  end
end
