defmodule TasukuLlmDocsParser.LlmParser.Mock do
  @behaviour TasukuLlmDocsParser.LLMParser

  @impl true
  def parse(raw) when is_binary(raw) do
    # Simple mock: title = first line, sections = paragraphs
    [first_line | _] = String.split(raw, "\n", parts: 2)
    sections =
      raw
      |> String.split("\n\n")
      |> Enum.map(&%{text: &1})

    {:ok, %{title: first_line, sections: sections}}
  end
end
