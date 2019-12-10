defmodule Validations do
  # # Generic validations
  def validate_integer(key, value) do
    case Integer.parse(value) do
      :error -> {key, {:error, "could not parse #{value} as integer"}}
      {int, _} -> {key, int}
    end
  end

  def validate_not_empty(key, nil), do: {key, {:error, "Missing #{key}."}}

  def validate_not_empty(key, value) do
    case byte_size(value) do
      0 -> {key, {:error, "Missing #{key}."}}
      _ -> {key, value}
    end
  end

  # # Business validations
  def validate_login({:valid_password, true, user}) do
    {:ok, user}
  end
  def validate_login({:valid_password, false, _user}) do
    {:incorrect_password}
  end
  def validate_login({:is_a_user, true, user, password}) do
    user = user |> hd
    valid_password = Argon2.verify_pass(password, user["password"])
    validate_login({:valid_password, valid_password, user})
  end
  def validate_login({:is_a_user, false, _user, _password}) do
    {:not_a_user}
  end
end
