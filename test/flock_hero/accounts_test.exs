defmodule FlockHero.AccountsTest do
  use FlockHero.DataCase

  alias FlockHero.Accounts

  describe "accounts" do
    alias FlockHero.Accounts.Account

    import FlockHero.AccountsFixtures

    @invalid_attrs %{name: nil, firebase_uid: nil, email: nil}

    test "list_accounts/0 returns all accounts" do
      account = account_fixture()
      assert Accounts.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      assert Accounts.get_account!(account.id) == account
    end

    test "create_account/1 with valid data creates a account" do
      valid_attrs = %{name: "some name", firebase_uid: "some firebase_uid", email: "some email"}

      assert {:ok, %Account{} = account} = Accounts.create_account(valid_attrs)
      assert account.name == "some name"
      assert account.firebase_uid == "some firebase_uid"
      assert account.email == "some email"
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()
      update_attrs = %{name: "some updated name", firebase_uid: "some updated firebase_uid", email: "some updated email"}

      assert {:ok, %Account{} = account} = Accounts.update_account(account, update_attrs)
      assert account.name == "some updated name"
      assert account.firebase_uid == "some updated firebase_uid"
      assert account.email == "some updated email"
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_account(account, @invalid_attrs)
      assert account == Accounts.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = Accounts.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      assert %Ecto.Changeset{} = Accounts.change_account(account)
    end
  end

  describe "upsert_from_claims/1" do
    test "creates new account from valid claims" do
      claims = %{"sub" => "test-uid", "email" => "test@example.com", "name" => "Test User"}
      {:ok, account} = Accounts.upsert_from_claims(claims)

      assert account.firebase_uid == "test-uid"
      assert account.email == "test@example.com"
      assert account.name == "Test User"
    end

    test "updates existing account from claims" do
      existing = account_fixture(firebase_uid: "test-uid", email: "old@example.com", name: "Old Name")
      claims = %{"sub" => "test-uid", "email" => "new@example.com", "name" => "New Name"}

      {:ok, updated} = Accounts.upsert_from_claims(claims)

      assert updated.id == existing.id
      assert updated.email == "new@example.com"
      assert updated.name == "New Name"
    end

    test "fails on invalid claims (missing required fields)" do
      claims = %{"sub" => "test-uid"}  # Missing email
      {:error, changeset} = Accounts.upsert_from_claims(claims)

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
