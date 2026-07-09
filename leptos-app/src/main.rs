use axum::{response::Html, routing::get, Router};
use leptos::prelude::*;

async fn handler() -> Html<String> {
    let owner = Owner::new();
    let body = owner.with(|| {
        view! {
            <main>
                <h1>"Hello, Leptos!"</h1>
                <p>"Minimal server-side rendered page."</p>
            </main>
        }
        .to_html()
    });

    Html(format!(
        "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><title>Leptos</title></head><body>{body}</body></html>"
    ))
}

#[tokio::main]
async fn main() {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    let addr = format!("0.0.0.0:{port}");

    let app = Router::new().route("/", get(handler));

    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    println!("Leptos SSR listening on {addr}");
    axum::serve(listener, app).await.unwrap();
}
