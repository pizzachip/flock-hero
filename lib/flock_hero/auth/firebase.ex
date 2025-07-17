defmodule FlockHero.Auth.Firebase do
  @moduledoc """
  Handles Firebase ID token verification.
  """

  @public_keys_url "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
  @cache_table :firebase_public_keys_cache
  @cache_ttl_ms 3_600_000  # 1 hour

  def fetch_public_keys(_req_module \\ nil) do  # Drop unused arg for simplicity
    case get_cached_keys() do
      {:ok, keys} -> keys
      :error ->
        req_options = Application.fetch_env!(:flock_hero, :req_options)
        response = Req.get!(@public_keys_url, req_options)
        if response.status == 200 do
          keys = response.body
                 |> Enum.map(fn {kid, cert} -> {kid, parse_cert(cert)} end)
                 |> Map.new()
          cache_keys(keys)
          keys
        else
          raise "Failed to fetch Firebase public keys: #{response.status}"
        end
    end
  end

  defp get_cached_keys do
    case :ets.lookup(@cache_table, :keys) do
      [{_, keys, timestamp}] ->
        if System.monotonic_time(:millisecond) - timestamp < @cache_ttl_ms do
          {:ok, keys}
        else
          :error
        end
      _ -> :error
    end
  end

  defp cache_keys(keys) do
    :ets.new(@cache_table, [:named_table, :public])  # Create if not exists
    :ets.insert(@cache_table, {:keys, keys, System.monotonic_time(:millisecond)})
  end

  def verify_token(token, req_module \\ Req) do
    project_id = Application.fetch_env!(:flock_hero, :firebase)[:project_id]
    issuer = "https://securetoken.google.com/#{project_id}"
    audience = project_id

    with {:ok, header} <- peek_header(token),
         kid when not is_nil(kid) <- header["kid"],
         keys <- fetch_public_keys(req_module),
         public_key when not is_nil(public_key) <- Map.get(keys, kid),
         signer <- Joken.Signer.create("RS256", public_key),
         {:ok, claims} <- Joken.verify(token, signer) do
      if valid_claims?(claims, issuer, audience) do
        {:ok, claims}
      else
        {:error, :invalid_claims}
      end
    else
      nil -> {:error, :missing_kid_or_key}
      {:error, reason} -> {:error, reason}
    end
  end

  defp valid_claims?(claims, issuer, audience) do
    sub = claims["sub"]
    iat = claims["iat"]
    exp = claims["exp"]
    now = Joken.current_time()

    claims["iss"] == issuer and
    claims["aud"] == audience and
    is_binary(sub) and byte_size(sub) > 0 and
    is_number(iat) and iat <= now and
    is_number(exp) and exp > now
  end

  defp peek_header(token) do
    case Joken.peek_header(token) do
      {:ok, header} -> {:ok, header}
      {:error, _} -> {:error, :invalid_header}
    end
  end

  defp parse_cert(cert_pem) do
    [{_, cert_der, _}] = :public_key.pem_decode(cert_pem)
    :public_key.pkix_decode_cert(cert_der, :otp)
    |> elem(1)
    |> elem(7)
    |> elem(2)
  end
end
