defmodule AmazinWeb.Router do
  use AmazinWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AmazinWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AmazinWeb.Plugs.SessionCart
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AmazinWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/products", ProductLive.Index, :index
    live "/products/new", ProductLive.Index, :new
    live "/products/:id/edit", ProductLive.Index, :edit
    live "/products/:id", ProductLive.Show, :show
    live "/products/:id/show/edit", ProductLive.Show, :edit
    live "/cart", CartLive.Show, :index
    live "/cart/success", CartLive.Success, :index
  end

  if Application.compile_env(:amazin, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AmazinWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
