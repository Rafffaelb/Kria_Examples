
`timescale 1ns / 1ps

module mag_squared (
    input  wire [31:0] data_in,   // [31:16] = Imag, [15:0] = Real
    output wire [31:0] power_out  // Real^2 + Imag^2 (Treat as 32-bit integer)
);

    // Split input
    wire signed [15:0] real_val = data_in[15:0];
    wire signed [15:0] imag_val = data_in[31:16];

    // Compute Power
    wire signed [31:0] re_sq;
    wire signed [31:0] im_sq;

    assign re_sq = real_val * real_val;
    assign im_sq = imag_val * imag_val;

    // Output Sum
    assign power_out = re_sq + im_sq;

endmodule
