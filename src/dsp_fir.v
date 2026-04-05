`timescale 1ps / 1ps
`default_nettype none

module dsp_fir (
    input  wire [7:0] data_in,    
    output wire [7:0] data_out,
    output wire       clk_adc,
    output wire       clk_dac,
    input  wire       mode,       
    input  wire       clk,      
    input  wire       rst_n     
);
    reg [1:0] phase;

    localparam M0 = 2'd0;
    localparam M1 = 2'd1;
    localparam M2 = 2'd2;
    localparam M3 = 2'd3;

    assign clk_adc = (phase == M1 || phase == M2) ? 1'b1 : 1'b0;
    assign clk_dac = ~clk_adc;

    reg signed [7:0]  fir_coeff [0:7];
    reg signed [7:0]  data_pipe [0:7];
    reg signed [7:0] mux_d [0:1], mux_c [0:1];
    reg signed [18:0] acc; 
    reg [7:0] result_reg; 
    
    integer i;
    wire signed [7:0] data_in_s = {~data_in[7], data_in[6:0]};
    
    // Combinational logics
    always @(*) begin
        case (phase)
            M0: begin 
                mux_d[0] = data_pipe[0]; mux_c[0] = fir_coeff[0]; 
                mux_d[1] = data_pipe[1]; mux_c[1] = fir_coeff[1];
            end
            M1: begin 
                mux_d[0] = data_pipe[2]; mux_c[0] = fir_coeff[2]; 
                mux_d[1] = data_pipe[3]; mux_c[1] = fir_coeff[3];
            end
            M2: begin
                mux_d[0] = data_pipe[4]; mux_c[0] = fir_coeff[4]; 
                mux_d[1] = data_pipe[5]; mux_c[1] = fir_coeff[5];
            end
            M3: begin
                mux_d[0] = data_pipe[6]; mux_c[0] = fir_coeff[6]; 
                mux_d[1] = data_pipe[7]; mux_c[1] = fir_coeff[7];
            end
        endcase
    end

    // Multipliers
    wire signed [15:0] p0 = mux_d[0] * mux_c[0];
    wire signed [15:0] p1 = mux_d[1] * mux_c[1];

    // Adders
    wire signed [17:0] math_out = p0 + p1;
    wire signed [18:0] next_acc = acc + math_out;

    // Sequential logics
    always @(posedge clk) begin
        if (!rst_n) begin
            phase <= M0;
            acc   <= 19'sd0;
            result_reg <= 8'h80; // Output is MSB flipped, this ensure the output 0
            for (i=0; i<8; i=i+1) begin
                fir_coeff[i] <= 8'sd0;
                data_pipe[i] <= 8'sd0;
            end
        end 
        else if (mode) begin
            // Coefficient loading
            fir_coeff[0] <= $signed(data_in);
            for (i=1; i<8; i=i+1) fir_coeff[i] <= fir_coeff[i-1];
            phase <= M0;
            acc   <= 19'sd0;
        end 
        else begin
            phase <= phase + 1'b1;
            
            if (phase == 2'b00) 
                acc <= math_out;
            else 
                acc <= next_acc;
            
            if (phase == M3) begin
                result_reg <= {~next_acc[14], next_acc[13:7]};
                data_pipe[0] <= data_in_s;
                data_pipe[1] <= data_pipe[0];
                data_pipe[2] <= data_pipe[1];
                data_pipe[3] <= data_pipe[2];
                data_pipe[4] <= data_pipe[3];
                data_pipe[5] <= data_pipe[4];
                data_pipe[6] <= data_pipe[5];
                data_pipe[7] <= data_pipe[6];

            end
        end
    end

    assign data_out = result_reg;

endmodule