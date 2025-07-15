defmodule TasukuLlmDocsParserWeb.DocumentController do
  use TasukuLlmDocsParserWeb, :controller

  @parser Application.compile_env!(:tasuku_llm_docs_parser, :llm_parser)

  def create(%{body_params: %{"doc" => raw_doc}} = conn, _opts) do
    {:ok, optimized} = @parser.parse(raw_doc)
    json(conn, %{status: "ok", data: optimized})
  end

  def create(conn, _),
    do:
      conn
      |> put_status(:bad_request)
      |> json(%{status: "error", message: "Missing \"doc\" field"})
end
