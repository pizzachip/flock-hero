defmodule FlockHero.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias FlockHero.Repo

  alias FlockHero.Accounts.Account
  alias FlockHero.Auth.Firebase

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end

  @doc """
  Upserts an account based on verified Firebase claims.
  Assumes claims have already been verified via Firebase.verify_token/1.
  """
  def upsert_from_claims(token) do
    with {:ok, claims} <- Firebase.verify_token(token) do
      attrs = %{
        firebase_uid: claims["sub"],
        email: claims["email"],
        name: claims["name"]  # If present in claims; Firebase may not always have it
      }
 
    case get_by_firebase_uid(attrs.firebase_uid) do
      nil ->
        %Account{}
        |> Account.changeset(attrs)
        |> Repo.insert()
 
      existing ->
        existing
        |> Account.changeset(attrs)
        |> Repo.update()
    end

    else
      {:error, reason} -> {:error, {:invalid_token, reason}}
    end
  end
 
  defp get_by_firebase_uid(uid) do
    Repo.get_by(Account, firebase_uid: uid)
  end  
end
