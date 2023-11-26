defmodule AmazinWeb.StripeWebhookHandler do
  @behaviour Stripe.WebhookHandler

  alias Amazin.Store

  @impl true
  def handle_event(%Stripe.Event{type: "checkout.session.completed"} = event) do
    cart_id = String.to_integer(event.data.object.metadata["cart_id"])
    Store.create_order(cart_id)
    :ok
  end

  @impl true
  def handle_event(_event), do: :ok
end
