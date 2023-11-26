defmodule Amazin.Store do
  @moduledoc """
  The Store context.
  """

  import Ecto.Query, warn: false
  alias Amazin.Repo
  alias Amazin.Store.Product
  alias Amazin.Store.Cart
  alias Amazin.Store.CartItem
  alias Amazin.Store.Order

  @doc """
  Subscribes you to product events
  """
  @spec subscribe_to_product_events() :: :ok | {:error, term()}
  def subscribe_to_product_events() do
    Phoenix.PubSub.subscribe(Amazin.PubSub, "products")
  end

  @doc """
  Broadcasts a product event
  """
  @spec broadcast_product_event(event :: atom(), product :: Product.t()) :: :ok | {:error, term()}
  def broadcast_product_event(event, product) do
    Phoenix.PubSub.broadcast(Amazin.PubSub, "products", {event, product})
  end

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    Repo.all(Product)
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Creates a product

  Publishes a `:product_created` event on success

  Returns resulting errors on failure
  """
  def create_product(attrs \\ %{}) do
    result =
      %Product{}
      |> Product.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, product} ->
        broadcast_product_event(:product_created, product)
        {:ok, product}

      error ->
        error
    end
  end

  @doc """
  Updates a product

  Publishes a `:product_updated` event on success

  Returns resulting errors on failure
  """
  def update_product(%Product{} = product, attrs) do
    result =
      product
      |> Product.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, product} ->
        broadcast_product_event(:product_updated, product)
        {:ok, product}

      error ->
        error
    end
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  def get_cart(cart_id) do
    Repo.get(Cart, cart_id)
  end

  def create_cart() do
    Repo.insert(%Cart{status: :open})
  end

  def list_cart_items(cart_id) do
    CartItem
    |> where([ci], ci.cart_id == ^cart_id)
    |> preload(:product)
    |> Repo.all()
  end

  def add_item_to_cart(cart_id, product) do
    %CartItem{cart_id: cart_id, product_id: product.id, quantity: 1}
    |> Repo.insert(
      conflict_target: [:cart_id, :product_id],
      on_conflict: [inc: [quantity: 1]]
    )
  end

  def create_order(cart_id) do
    cart_id
    |> get_cart()
    |> Cart.changeset(%{status: :completed})
    |> Repo.update()
    |> case do
      {:ok, cart} ->
        Repo.insert(%Order{cart_id: cart.id})

      error ->
        error
    end
  end
end
