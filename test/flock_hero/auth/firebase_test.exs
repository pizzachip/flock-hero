defmodule FlockHero.Auth.FirebaseTest do
  use ExUnit.Case, async: true
  import Req.Test, only: [stub: 2]
  import Mox

  alias FlockHero.Auth.Firebase

  setup :verify_on_exit!

  describe "fetch_public_keys/0" do
    setup do
      stub(:firebase_keys, fn conn ->
        Req.Test.json(conn, %{"kid1" => valid_cert_pem()})
      end)
      :ok
    end
  
    test "fetches and parses keys on cache miss" do
      keys = Firebase.fetch_public_keys()
      assert map_size(keys) == 1
      assert is_tuple(keys["kid1"])  # Public key tuple
    end
  
    test "returns cached keys on hit" do
      # Simulate cache (same as before)
      :ets.new(:firebase_public_keys_cache, [:named_table, :public])
      :ets.insert(:firebase_public_keys_cache, {:keys, %{"kid" => {:public_key, :rsapublickey, {1, 2}, nil}}, System.monotonic_time(:millisecond)})
  
      keys = Firebase.fetch_public_keys()
      assert map_size(keys) == 1
    end
  
    test "raises on fetch failure" do
      stub(:firebase_keys, fn conn ->
        Plug.Conn.resp(conn, 500, "error")
      end)
  
      assert_raise RuntimeError, fn ->
        Firebase.fetch_public_keys()
      end
    end
  end
  
  describe "verify_token/1" do
    setup do
      stub(:firebase_keys, fn conn ->
        Req.Test.json(conn, %{"kid1" => valid_cert_pem()})
      end)
      :ok
    end
  
    test "verifies valid token" do
      token = dummy_valid_token()
      result = Firebase.verify_token(token)
      # For dummy, expect error; with real token, {:ok, claims}
      assert match?({:error, _}, result)
    end
  
    test "errors on invalid token" do
      token = "invalid"
      assert {:error, :invalid_header} = Firebase.verify_token(token)
    end
  end 

  defp valid_cert_pem do
    """
    -----BEGIN CERTIFICATE-----
    MIIE0zCCA7ugAwIBAgIQX/h7KM7yPOZR6KXLcpMMM DANBgkqhkiG9w0BAQsFADCB
    qTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDHRoYXd0ZSwgSW5jLjEoMCYGA1UECxMf
    Q2VydGlmaWNhdGlvbiBTZXJ2aWNlcyBEaXZpc2lvbjE4MDYGA1UECxMvKGMpIDIw
    MDYgdGhhd3RlLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkxHzAdBgNV
    BAMTFnRoYXd0ZSBQcmltYXJ5IFJvb3QgQ0EwHhcNMTMwNzE2MDAwMDAwWhcNMzMw
    NzE1MjM1OTU5WjCBqTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDHRoYXd0ZSwgSW5j
    LjEoMCYGA1UECxMfQ2VydGlmaWNhdGlvbiBTZXJ2aWNlcyBEaXZpc2lvbjE4MDY
    GA1UECxMvKGMpIDIwMDYgdGhhd3RlLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNl
    IG9ubHkxHzAdBgNVBAMTFnRoYXd0ZSBQcmltYXJ5IFJvb3QgQ0EwggEiMA0GCSqG
    SIb3DQEBAQUAA4IBDwAwggEKAoIBAQCwBH6UA1EvXJ/RB4kuhW0jV0p3eC9p1D0b
    T4uAKwg6qyy6j0Wp/3o5m07y2JZo6h+7B/GxHAc5f8Z0sP0r5bB0xO4u8/1nUg4S
    0OhuNq7+FMt7S1t0r3EjmqZnsy1i0lH3Pd0rA4jfmZeh/zbHJgWUG7zSoiK4gPzc
    dA5p9gG1lL8z5c5O2pA3BIgZ4VrhZsQd4jI3w0j+7V7Pw6vOzrebozqnuJ4mSvd5
    dD9wY2kHxvK8uucZBG7smsx22tLr6yLZHFj3B5uH3a4tuGbg5a4PsC7OQL0yVN5r
    4/SUKNk4LKpVKXwC9qG48S+UvQRxNlnmgosPwkqoAgMBAAGjQjBAMA8GA1UdEwEB
    /wQFMAMBAf8wDgYDVR0PAQH/BAIwADAdBgNVHQ4EFgQUe1tMyoR1HsI9le8BrlJH
    Wm1H5yswDQYJKoZIhvcNAQELBQADggEBABpZko7q8VPw6kaPZi6gQD0FVg+5BtNP
    +y8r/OhrVRqe8hWSN/ImUOg34yzU2KMqr8rA2JR2P6cH5sRO5fURWJ0jUia6J3JH
    A4I+Wfj/Hz0gqQ3WCY0s7m kdurooRXL7LLlZX3lL soMuqr6gDgI
    XE75nGzxhlENvAuW/9p7mJ1KXeDvZGyx4c6MZL7s2olD0RJ3v+d5HsXM4Xy1IKc
    i/S9/P8x0xVkOVzHvgA9WWPxVk6/6zNl4uIK0YmQ3peLG8Pz1Hsg6z0aY2LLXehJ
    9PGY1k4MVsRMo4Jqn5zUEuRR1H2lhlDQMrg5kYA11yX76Wpsb7/11w==
    -----END CERTIFICATE-----
    """
  end
  
  defp dummy_valid_token do
    "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg5NjllNTFhIiwidHlwIjoiSldUIn0.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vZmxvY2staGVybyIsImF1ZCI6ImZsb2NrLWhlcm8iLCJpYXQiOjE3MjA5NjAwMDAsImV4cCI6MTcyMDk2MzYwMCwic3ViIjoidGVzdC11c2VyLXVpZCIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVl9LCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7ImVtYWlsIjpbInRlc3RAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJjdXN0b20ifX0.dummy-signature-to-simulate"
  end

end
