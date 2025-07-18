defmodule FlockHero.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FlockHero.Accounts` context.
  """

  @doc """
  Generate a unique account firebase_uid.
  """
  def unique_account_firebase_uid, do: "some firebase_uid#{System.unique_integer([:positive])}"

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{
        email: "some email",
        firebase_uid: unique_account_firebase_uid(),
        name: "some name"
      })
      |> FlockHero.Accounts.create_account()

    account
  end
end
