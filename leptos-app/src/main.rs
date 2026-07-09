use leptos::prelude::*;
use std::hint::black_box;
use std::time::Instant;

const ITERATIONS: usize = 1_000_000;

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

fn render_once() -> usize {
    let owner = Owner::new();
    let html = owner.with(|| SsrPage().to_html());
    html.len()
}

fn main() {
    let start = Instant::now();
    let mut total_bytes: usize = 0;
    for _ in 0..ITERATIONS {
        total_bytes += render_once();
    }
    let total_ns = start.elapsed().as_nanos();
    black_box(total_bytes);

    let ns_per_op = total_ns as f64 / ITERATIONS as f64;
    let bytes_per_op = total_bytes / ITERATIONS;

    println!(
        "{{\"framework\":\"leptos\",\"iterations\":{},\"ns_per_op\":{:.2},\"bytes_per_op\":{}}}",
        ITERATIONS, ns_per_op, bytes_per_op
    );
}
