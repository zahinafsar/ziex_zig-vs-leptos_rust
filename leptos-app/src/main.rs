use actix_web::{web, App as ActixApp, HttpServer};
use leptos::config::LeptosOptions;
use leptos::prelude::*;
use leptos_actix::{generate_route_list, LeptosRoutes};
use leptos_router::components::{Route, Router, Routes};
use leptos_router::path;

#[component]
fn Page() -> impl IntoView {
    let items: Vec<u32> = (0..50).map(|_| 1).collect();

    view! {
        <main>
            {items
                .into_iter()
                .enumerate()
                .map(|(i, v)| view! { <div>"SSR " {v} "-" {i}</div> })
                .collect_view()}
        </main>
    }
}

#[component]
fn App() -> impl IntoView {
    view! {
        <Router>
            <Routes fallback=|| "Not found.">
                <Route path=path!("") view=Page/>
            </Routes>
        </Router>
    }
}

fn shell() -> impl IntoView {
    view! {
        <!DOCTYPE html>
        <html lang="en">
            <head>
                <meta charset="utf-8"/>
                <meta name="viewport" content="width=device-width, initial-scale=1"/>
                <title>"Leptos"</title>
            </head>
            <body>
                <App/>
            </body>
        </html>
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let addr = std::net::SocketAddr::from(([0, 0, 0, 0], 3000));
    let options = LeptosOptions::builder()
        .output_name("leptos-app")
        .site_addr(addr)
        .build();

    let routes = generate_route_list(App);

    HttpServer::new({
        let options = options.clone();
        move || {
            ActixApp::new()
                .app_data(web::Data::new(options.clone()))
                .leptos_routes(routes.clone(), shell)
        }
    })
    .bind(addr)?
    .run()
    .await
}
