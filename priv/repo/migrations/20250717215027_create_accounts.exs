defmodule FlockHero.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :firebase_uid, :string
      add :email, :string
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accounts, [:firebase_uid])
  end
end
