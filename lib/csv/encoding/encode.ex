defprotocol CSV.Encode do
  @fallback_to_any true
  @moduledoc """
  Implement encoding for your data types.
  """

  @doc """
  The encode function to implement, gets passed the data and env as a keyword
  list containing the currently used separator and delimiter.
  """
  def encode(data, separator, delimiter, escaping)
end

defimpl CSV.Encode, for: Any do
  @doc """
  Default encoding implementation, uses the string protocol and feeds into the
  string encode implementation
  """

  def encode(data, _separator, _delimiter, false), do: to_string(data)
  def encode(data, separator, delimiter, true) do
    data |> to_string() |> CSV.Encode.encode(separator, delimiter, true)
  end
end

defimpl CSV.Encode, for: BitString do
  use CSV.Defaults

  @doc """
  Standard string encoding implementation, escaping cells with double quotes
  where necessary.
  """

  def encode(data, _separator, _delimiter, false), do: data
  def encode(data, separator, delimiter, true) do
    cond do
      String.contains?(data, [
        << separator :: utf8 >>,
        delimiter,
        << @carriage_return :: utf8 >>,
        << @newline :: utf8 >>,
        << @double_quote :: utf8 >>
      ]) ->
        << @double_quote :: utf8 >> <>
      (data |> escape |> String.replace(
        << @double_quote :: utf8 >>,
        << @double_quote :: utf8 >> <> << @double_quote :: utf8 >>)) <>
        << @double_quote :: utf8 >>
      true ->
        data |> escape
    end
  end

  defp escape(cell) do
    cell |>
      String.replace(<< @newline :: utf8 >>, "\\n") |>
      String.replace(<< @carriage_return :: utf8 >>, "\\r") |>
      String.replace("\t", "\\t")
  end
end
