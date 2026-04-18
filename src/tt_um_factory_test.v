`default_nettype none

module tt_um_factory_test (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  
  dsp_fir m1 (
    .data_in(ui_in),
    .data_out(uo_out),
    .clk_dac(uio_out[1]),
    .clk_adc(uio_out[0]),
    .mode(uio_in[2]),
    .clk(clk),
    .rst_n(rst_n)
  );
  // avoid linter warning about unused pins:
  wire _unused_pins = &{ena, uio_out[7:2], uio_oe[7:2], uio_in[7:1],1'b0};
  
  // Tie unused outputs to 0
  assign uio_out[2] = 1'b0;
  assign uio_out[3] = 1'b0;
  assign uio_out[4] = 1'b0;
  assign uio_out[5] = 1'b0;
  assign uio_out[6] = 1'b0;
  assign uio_out[7] = 1'b0;
  
  // IO 1 and 2 is ADC CLK
  assign uio_oe[0]  = 1'b1;
  assign uio_oe[1]  = 1'b1;
  assign uio_oe[2]  = 1'b0;
  assign uio_oe[3]  = 1'b0;
  assign uio_oe[4]  = 1'b0;
  assign uio_oe[5]  = 1'b0;
  assign uio_oe[6]  = 1'b0;
  assign uio_oe[7]  = 1'b0;

endmodule  // tt_um_factory_test