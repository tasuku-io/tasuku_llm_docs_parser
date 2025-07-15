defmodule TasukuLlmDocsParser.LLMParser do
  @moduledoc """
  Behaviour for parsing raw docs into LLM-optimized structure.
  """

  @callback parse(String.t()) ::
              {:ok, %{title: String.t(), sections: [map()]}}
              | {:error, String.t()}
end
