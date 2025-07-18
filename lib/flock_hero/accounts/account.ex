defmodule FlockHero.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :name, :string
    field :firebase_uid, :string
    field :email, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:firebase_uid, :email, :name])
    |> validate_required([:firebase_uid, :email, :name])
    |> unique_constraint(:firebase_uid)
  end
end
