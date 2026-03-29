module dsp_fir(
    input  wire [7:0] data_in,    // Dedicated inputs
    output wire [7:0] data_out,   // Dedicated outputs
    input  wire       mode,       // 0: filter run mode, 1: coefficient load mode
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    localparam M1 = 1'd0;  // Reset state
    localparam M2 = 1'd1;  // First coeffcient
    // localparam L  = 4'd2;  // Loading stage

    reg state_q, state_d;

    // FILTER COEFFICIENTS
    // Register for 8 x 8 bit filter coefficients 
    reg signed [7:0] fir_coeff [0:7];
    reg signed [7:0] data_pipeline[0:7]; //input data shift register

    reg signed [7:0] data_pipeline_split [0:3];
    reg signed [7:0] fir_coefficient_split [0:3];
    reg [18:0] carry_over;
    reg [18:0] result_adder_q; 
    wire [18:0] result_adder_d;

    reg output_valid;

    wire [15:0] result_partial [0:3];

    integer  i;

    always @(posedge clk) begin
        if (!rst_n) begin

            state_q <= M1; // Reset state back to M1

            for(i=0; i<8; i=i+1) begin
                fir_coeff[i] <= 8'b0;
                data_pipeline[i] <= 8'd0;
            end
        end
        else begin
            if (mode == 1'b1) begin // Load the coefficients when mode = 1
                fir_coeff[0] <= data_in;
                fir_coeff[1] <= fir_coeff[0];
                fir_coeff[2] <= fir_coeff[1];
                fir_coeff[3] <= fir_coeff[2];
                fir_coeff[4] <= fir_coeff[3];
                fir_coeff[5] <= fir_coeff[4];
                fir_coeff[6] <= fir_coeff[5];
                fir_coeff[7] <= fir_coeff[6];
                
                // Let the filter start fresh from mode switch
                state_q <= M1;
                result_adder_q <= 19'b0;

            end 
            else begin  // Shift data when mode = 0
                data_pipeline[0] <= data_in;
                data_pipeline[1] <= data_pipeline[0];
                data_pipeline[2] <= data_pipeline[1];
                data_pipeline[3] <= data_pipeline[2];
                data_pipeline[4] <= data_pipeline[3];
                data_pipeline[5] <= data_pipeline[4];
                data_pipeline[6] <= data_pipeline[5];
                data_pipeline[7] <= data_pipeline[6];

                state_q <= state_d;
                result_adder_q <= result_adder_d;
            end
        end 
    end

    // Combinational logics
    always @(*) begin
        case (state_q)
            M1 : begin
                state_d = M2;

                output_valid = 1'b0;

                data_pipeline_split[0] = data_pipeline[0];
                data_pipeline_split[1] = data_pipeline[1];
                data_pipeline_split[2] = data_pipeline[2];
                data_pipeline_split[3] = data_pipeline[3];

                fir_coefficient_split[0] = fir_coeff[0];
                fir_coefficient_split[1] = fir_coeff[1];
                fir_coefficient_split[2] = fir_coeff[2];
                fir_coefficient_split[3] = fir_coeff[3];

                carry_over = 19'b0;
            end
            M2 : begin
                state_d = M1;

                output_valid = 1'b1;
                
                data_pipeline_split[0] = data_pipeline[4];
                data_pipeline_split[1] = data_pipeline[5];
                data_pipeline_split[2] = data_pipeline[6];
                data_pipeline_split[3] = data_pipeline[7];

                fir_coefficient_split[0] = fir_coeff[4];
                fir_coefficient_split[1] = fir_coeff[5];
                fir_coefficient_split[2] = fir_coeff[6];
                fir_coefficient_split[3] = fir_coeff[7];

                carry_over = result_adder_q;
            end 
        endcase
    end

    assign data_out= output_valid ? result_adder_q[15:8] : 8'b0;


    multiplier_x4 m1 (
        .a0(data_pipeline_split[0]),
        .a1(data_pipeline_split[1]),
        .a2(data_pipeline_split[2]),
        .a3(data_pipeline_split[3]),
        .b0(fir_coefficient_split[0]),
        .b1(fir_coefficient_split[1]),
        .b2(fir_coefficient_split[2]),
        .b3(fir_coefficient_split[3]),
        .out0(result_partial[0]),
        .out1(result_partial[1]),
        .out2(result_partial[2]),
        .out3(result_partial[3])
    );

    adder_x5 m2 (
        .in0(result_partial[0]),
        .in1(result_partial[1]),
        .in2(result_partial[2]),
        .in3(result_partial[3]),
        .carry_over(carry_over),
        .out(result_adder_d)
    );

    // TEMPORARY
    // Prevent registers from be optimized out
    // assign data_out = fir_coeff[data_in[2:0]];

endmodule

module multiplier_x4(
    input  wire signed [7:0] a0,
    input  wire signed [7:0] a1,
    input  wire signed [7:0] a2,
    input  wire signed [7:0] a3,
    input  wire signed [7:0] b0,
    input  wire signed [7:0] b1,
    input  wire signed [7:0] b2,
    input  wire signed [7:0] b3,
    output wire signed [15:0] out0,
    output wire signed [15:0] out1,
    output wire signed [15:0] out2,
    output wire signed [15:0] out3
);
    assign out0 = a0*b0;
    assign out1 = a1*b1;
    assign out2 = a2*b2;
    assign out3 = a3*b3;
endmodule

module adder_x5 (
    input  wire signed [15:0] in0,
    input  wire signed [15:0] in1,
    input  wire signed [15:0] in2,
    input  wire signed [15:0] in3,
    input  wire signed [18:0] carry_over,
    output wire signed [18:0] out
);
    assign out = in0 + in1 + in2 + in3 + carry_over;
endmodule