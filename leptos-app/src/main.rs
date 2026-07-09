use actix_web::{get, App, HttpResponse, HttpServer, Responder};
use leptos::prelude::*;

#[component]
fn SsrPage() -> impl IntoView {
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

#[get("/")]
async fn handler() -> impl Responder {
    let owner = Owner::new();
    let body = owner.with(|| SsrPage().to_html());

    HttpResponse::Ok()
        .content_type("text/html; charset=utf-8")
        .body(format!(
            "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><title>Leptos</title></head><body>{body}</body></html>"
        ))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    let addr = format!("0.0.0.0:{port}");

    println!("Leptos SSR listening on {addr}");
    HttpServer::new(|| App::new().service(handler))
        .bind(&addr)?
        .run()
        .await
}
