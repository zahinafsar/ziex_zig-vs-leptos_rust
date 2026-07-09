const std = @import("std");
const builtin = @import("builtin");
const zx = @import("zx");

const iterations: usize = 1_000_000;

pub fn main(init: zx.Init) !void {
    _ = init;
    if (comptime builtin.target.cpu.arch != .wasm32) {
        try bench();
    }
}

fn bench() !void {
    const SsrPage = @import("SsrPage").SsrPage;
    const io = zx.io();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var total_bytes: usize = 0;
    const start = std.Io.Timestamp.now(io, .awake);

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        _ = arena.reset(.retain_capacity);
        const allocator = arena.allocator();

        const component = SsrPage(allocator);

        var aw = std.Io.Writer.Allocating.init(allocator);
        try component.render(&aw.writer, .{});
        total_bytes += aw.written().len;
    }

    const end = std.Io.Timestamp.now(io, .awake);
    const elapsed_ns: u64 = @intCast(start.durationTo(end).nanoseconds);
    const ns_per_op = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(iterations));

    var buf: [256]u8 = undefined;
    var sw = std.Io.File.stdout().writerStreaming(io, &buf);
    const out = &sw.interface;
    try out.print(
        "{{\"framework\":\"ziex\",\"iterations\":{d},\"ns_per_op\":{d:.2},\"bytes_per_op\":{d}}}\n",
        .{ iterations, ns_per_op, total_bytes / iterations },
    );
    try out.flush();
}

pub const std_options = zx.std_options;

pub const config = .{
    .csr = false,
};
