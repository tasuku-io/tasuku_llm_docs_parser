defmodule TasukuLlmDocsParser.Agent do
  @moduledoc """
  Behaviour for agents that can process LLM-optimized documents.
  """

  alias NetsukeAgents.Components.SystemPromptGenerator
  alias NetsukeAgents.{BaseAgentConfig, BaseAgent, AgentMemory}

  # Set up initial memory for agent
  agent_memory =
    AgentMemory.new()
    |> AgentMemory.add_message("assistant", %{
      reply: "Hello! I’m your dedicated API Documentation Parser agent. I excel at reading any format (Markdown, code comments, HTML, plain text) and extracting API specifications into a clean, normalized JSON schema optimized for LLM ingestion. Send me your API docs, and I’ll return the structured JSON ready for machine use."
    })

  custom_system_prompt = SystemPromptGenerator.new(
    background: [
      "You are an expert API‐documentation parser whose sole task is to convert arbitrary API docs (Markdown, HTML, plain text, code comments, etc.) into a normalized JSON schema optimized for LLM ingestion.",
      "You understand HTTP endpoints, methods, path parameters, query/header/body parameters, response codes, media types, and grouping by tags or categories."
    ],
    steps: [
      "Scan the input text and locate each endpoint declaration (e.g. @app.route, HTTP verb headings, code samples).",
      "For each endpoint, extract: HTTP method(s), path (with placeholders), one‐line summary, list of produces/media types, parameters (name, location, type, required, description/default), and response codes with descriptions.",
      "Normalize parameter names and types (e.g. integer, string, boolean), and convert path/query/header/body distinctions into a consistent `in` field.",
      "Group endpoints by their logical tag or category if present; otherwise assign a default group like “Miscellaneous.”",
      "Build a single JSON object where each top‐level key is a tag and its value is an array of endpoint objects."
    ],
    output_instructions: [
      "Emit _only_ valid JSON abiding these rules: use double quotes for keys/strings, no comments or extra fields, and no trailing commas.",
      "Structure must be: `{ \"TagName\": [ { \"path\": \"/foo\", \"methods\": [\"GET\"], \"summary\": \"...\", \"produces\": [\"application/json\"], \"parameters\": [ { \"in\":\"path\",\"name\":\"id\",\"type\":\"integer\",\"required\":true,\"description\":\"...\" } ], \"responses\": { \"200\":\"OK description\" } }, … ], … }`",
      "If any information is missing (e.g. media types or summaries), omit the field or use an empty array/object, but do not insert placeholders.",
      "Do not include any markdown, prose, or explanation—output exactly one JSON blob."
    ]
  )

  # Create config for the agent
  @config BaseAgentConfig.new([
    memory: agent_memory,
    input_schema: %{
      original_docs: :string
    },
    output_schema: %{parsed_docs: :string},
    system_prompt_generator: custom_system_prompt
  ])

  @doc """
  Runs the agent with the provided input.
  """
  def run_agent(input) do
    agent = BaseAgent.new("agent", @config)

    {:ok, _updated_agent, response} = BaseAgent.run(agent, %{original_docs: input})
    IO.inspect(response, label: "Agent Response")
    response.parsed_docs
  end

end
