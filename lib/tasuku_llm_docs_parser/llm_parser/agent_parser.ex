defmodule TasukuLlmDocsParser.LlmParser.AgentParser do
  @moduledoc """
  Implementation of LlmParser behaviour using the NetsukeAgents-based Agent.
  """

  @behaviour TasukuLlmDocsParser.LlmParser

  alias TasukuLlmDocsParser.Agent

  @impl TasukuLlmDocsParser.LlmParser
  def parse(raw_doc) do
    try do
      # Run the agent with the raw documentation
      agent_response = Agent.run_agent(raw_doc)

      # Extract the reply from the NetsukeAgents response
      json_string = case agent_response do
        %{reply: reply} when is_binary(reply) -> reply
        reply when is_binary(reply) -> reply
        _ -> Jason.encode!(agent_response)
      end

      # Try to decode and validate it's valid JSON, then return as-is
      case Jason.decode(json_string) do
        {:ok, parsed_json} ->
          {:ok, parsed_json}

        {:error, _decode_error} ->
          # If JSON decode fails, wrap the response
          {:ok, %{
            "error" => "Invalid JSON response",
            "raw_response" => json_string
          }}
      end
    rescue
      error ->
        {:error, "Agent parsing failed: #{Exception.message(error)}"}
    end
  end
end
