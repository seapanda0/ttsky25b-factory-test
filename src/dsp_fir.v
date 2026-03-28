module dsp_fir(
    input  wire [7:0] data_in,    // Dedicated inputs
    output wire [7:0] data_out,   // Dedicated outputs
    input  wire       mode,       // 0: filter run mode, 1: coefficient load mode
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // localparam R = 4'd0;  // Reset state
    // localparam C0 = 4'd1; // First coeffcient
    // localparam C1 = 4'd2; //
    // localparam C2 = 4'd3; //
    // localparam C3 = 4'd4;
    // localparam C4 = 4'd5;
    // localparam C5 = 4'd6;
    // localparam C6 = 4'd7;
    // localparam C7 = 4'd8;
    // localparam M = 4'd7;  // First math stage

    // FSM Disabled

    // reg [3:0] state, next_state;

    // // FSM Switching
    // always @(*) begin
    //     if (!rst_n) begin
    //         next_state <= R;
    //     end
    //     else begin
    //         case (state)
    //             R : next_state <= C0; 
    //             C0 : next_state <= C1;
    //             C1 : next_state <= C2;
    //             C2 : next_state <= C3;
    //             C3 : next_state <= C4;
    //             C4 : next_state <= C5;
    //             C5 : next_state <= C6;
    //             C6 : next_state <= C7;
    //             C7 : next_state <= M;
    //             default: next_state <= R; 
    //         endcase 
    //     end
    // end

    // always @(posedge clk) begin
    //     if(!rst_n) begin
    //         state <= R;
    //     end
    //     else begin
    //         state <= next_state;
    //     end
    // end

    // FILTER COEFFICIENTS
    // Register for 8 x 8 bit filter coefficients 
    reg signed [7:0] fir_coeff [0:7];

    // Load the coefficients when mode = 1
    integer  i;
    always @(posedge clk) begin
        if (!rst_n) begin
            for(i=0; i<8; i=i+1) begin
                fir_coeff[i] <= 8'b0;
            end
        end
        else if (mode == 1'b1) begin
            fir_coeff[0] <= data_in;
            fir_coeff[1] <= fir_coeff[0];
            fir_coeff[2] <= fir_coeff[1];
            fir_coeff[3] <= fir_coeff[2];
            fir_coeff[4] <= fir_coeff[3];
            fir_coeff[5] <= fir_coeff[4];
            fir_coeff[6] <= fir_coeff[5];
            fir_coeff[7] <= fir_coeff[6];
        end
    end

    // DATA PIPELINE & SHIFTING
    reg signed [7:0] data_pipeline[0:7]; //input data shift register
    integer  j;
    always @(posedge clk) begin 
        if(!rst_n) begin 
            for (j = 0; j < 8; j = j + 1) begin
                data_pipeline[j] <= 8'sd0;
            end
        end else if (mode == 1'b0) begin //only shift data when in run mode
            data_pipeline[0] <= data_in;
            data_pipeline[1] <= data_pipeline[0];
            data_pipeline[2] <= data_pipeline[1];
            data_pipeline[3] <= data_pipeline[2];
            data_pipeline[4] <= data_pipeline[3];
            data_pipeline[5] <= data_pipeline[4];
            data_pipeline[6] <= data_pipeline[5];
            data_pipeline[7] <= data_pipeline[6];
        end
    end

    // DSP FILTER
    reg signed [15:0] mult_reg [0:7]; //multiplying 8bit * 8bit gives a 16 bit result
    integer  k;
    integer  l;
    always @(posedge clk)begin 
        if (!rst_n)begin 
            for (k = 0; k < 8; k = k + 1) begin
                mult_reg[k] <= 16'sd0;
            end
        end else if (mode==1'b0)begin //perform multiplication and store in a register immediately
            for (l = 0; l < 8; l = l + 1) begin
                mult_reg[l] <= data_pipeline[l] * fir_coeff[l]; 
            end
        end
    end
    
    wire signed [18:0] sum; //summing eight 16-bit numbers requires 3 extra bits to prevent overflow
    
    assign sum = mult_reg[0] + mult_reg[1] + 
                 mult_reg[2] + mult_reg[3] + 
                 mult_reg[4] + mult_reg[5] + 
                 mult_reg[6] + mult_reg[7];
                 
    //scale the output, drop the lower 8 bits and take the next 8 bits
    
    assign data_out=sum[15:8];

    // TEMPORARY
    // Prevent registers from be optimized out
    // assign data_out = fir_coeff[data_in[2:0]];

endmodule
