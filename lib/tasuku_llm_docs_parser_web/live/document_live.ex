defmodule TasukuLlmDocsParserWeb.DocumentLive do
  use TasukuLlmDocsParserWeb, :live_view

  @parser Application.compile_env!(:tasuku_llm_docs_parser, :llm_parser)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       raw_doc: "",
       result: nil,
       error: nil,
       processing: false,
       copied: false
     )}
  end

  @impl true
  def handle_event("parse", %{"doc" => raw}, socket) do
    # Set processing state immediately and preserve the input text
    socket = assign(socket, processing: true, error: nil, raw_doc: raw)

    # Send async message to self to perform the parsing
    send(self(), {:parse_document, raw})

    {:noreply, socket}
  end

  @impl true
  def handle_event("copy_to_clipboard", _params, socket) do
    # We'll use JavaScript to copy to clipboard on the client side
    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: Jason.encode!(socket.assigns.result, pretty: true)})
    }
  end

  @impl true
  def handle_event("clipboard_copied", _params, socket) do
    # Temporarily show copied feedback
    Process.send_after(self(), :clear_copied, 2000)
    {:noreply, assign(socket, copied: true)}
  end

  @impl true
  def handle_info({:parse_document, raw}, socket) do
    case @parser.parse(raw) do
      {:ok, optimized} ->
        {:noreply,
         assign(socket,
           raw_doc: raw,
           result: optimized,
           error: nil,
           processing: false
         )}
      _->
      {:noreply,
        assign(socket,
          error: "Failed to parse document",
          result: nil,
          processing: false
        )}

      # {:error, err} ->
      #   {:noreply,
      #    assign(socket,
      #      error: err,
      #      result: nil,
      #      processing: false
      #    )}
    end
  end

  @impl true
  def handle_info(:clear_copied, socket) do
    {:noreply, assign(socket, copied: false)}
  end
end
