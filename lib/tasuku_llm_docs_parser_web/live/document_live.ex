defmodule TasukuLlmDocsParserWeb.DocumentLive do
  use TasukuLlmDocsParserWeb, :live_view

  @parser Application.compile_env!(:tasuku_llm_docs_parser, :llm_parser)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       raw_doc: "",
       result: nil,
       error: nil
     )}
  end

  @impl true
  def handle_event("parse", %{"doc" => raw}, socket) do
    case @parser.parse(raw) do
      {:ok, optimized} ->
        {:noreply,
         assign(socket,
           raw_doc: raw,
           result: optimized,
           error: nil
         )}
      _->
      {:noreply,
        assign(socket,
          error: "Failed to parse document",
          result: nil
        )}

      # {:error, err} ->
      #   {:noreply,
      #    assign(socket,
      #      error: err,
      #      result: nil
      #    )}
    end
  end
end
